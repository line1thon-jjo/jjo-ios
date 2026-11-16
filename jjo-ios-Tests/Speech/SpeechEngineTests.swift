//
//  SpeechEngineTests.swift
//  jjo-ios-Tests
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation
import Testing
@testable import jjo_ios

struct SpeechEngineTests {
    private static let demoSynth = SpeechSynth.demo()
    private static let demo = try? demoSynth.analyze(script: SpeechSynth.demoScript)
    private let script = "저는 오늘 발표를 시작하겠습니다. 이번 주제는 결제 문화입니다."
    private let counting = "하나입니다. 둘입니다. 셋입니다. 넷입니다. 다섯입니다. 여섯입니다. 일곱입니다."

    private func index(_ part: String, in text: String) -> Int {
        SpeechSynth.index(of: part, in: text)
    }

    private func run(
        _ script: String,
        spoken: String? = nil,
        overrides: [Int: SpeechSynth.Override] = [:],
        gaps: [Int: Double] = [:],
        config: SpeechConfig = .default,
        words edit: ([WordTiming]) -> [WordTiming] = { $0 }
    ) throws -> (result: AnalysisResult, synth: SpeechSynth) {
        let synth = SpeechSynth(spoken ?? script, overrides: overrides, gaps: gaps)
        return (try synth.analyze(script: script, words: edit(synth.words), config: config), synth)
    }

    private func runInsert(
        _ insert: SpeechSynth.Insert,
        extra: ((_ startMs: Double) -> WordTiming)? = nil
    ) throws -> (result: AnalysisResult, synth: SpeechSynth, after: Int, next: Int) {
        let after = index("오늘", in: script) + 1
        let next = index("발", in: script)
        let synth = SpeechSynth(script, inserts: [after: insert])
        var words = synth.words
        if let extra, let position = words.firstIndex(where: { $0.text == "오늘" }),
           let following = synth.truth.first(where: { $0.idx == next }) {
            words.insert(extra(following.startMs - insert.post - insert.dur), at: position + 1)
        }
        return (try synth.analyze(script: script, words: words), synth, after, next)
    }

    private func syllable(_ result: AnalysisResult, _ idx: Int) throws -> Syllable {
        try #require(result.syllables.first { $0.idx == idx })
    }

    private func errorCode(_ body: () throws -> AnalysisResult) -> AnalysisErrorCode? {
        do {
            _ = try body()
            return nil
        } catch {
            return (error as? AnalysisError)?.code
        }
    }

    @Test func encodesContract() throws {
        let result = try #require(Self.demo)
        let data = try JSONEncoder().encode(result)
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(json["version"] as? String == "1.1")
        let first = try #require((json["syllables"] as? [[String: Any]])?.first)
        for key in ["startMs", "pitchLevel", "pitchSt", "volumeDb", "lowVolume", "inferred"] {
            #expect(first[key] != nil)
        }
        #expect(json["unclearRanges"] != nil)
        #expect((json["summary"] as? [String: Any])?["typicalPauseMs"] != nil)
        #expect(try JSONDecoder().decode(AnalysisResult.self, from: data) == result)
    }

    @Test func timesSyllables() throws {
        let result = try #require(Self.demo)
        let errors = try Self.demoSynth.truth.map { abs(Double(try syllable(result, $0.idx).startMs) - $0.startMs) }
        #expect(NumPy.median(errors) < 30)
        #expect(Double(errors.count(where: { $0 < 80 })) / Double(errors.count) > 0.85)
    }

    @Test func detectsPlantedHabits() throws {
        let result = try #require(Self.demo)
        let marks = SpeechSynth.demoMarks
        let habits = Dictionary(uniqueKeysWithValues: result.habits.map { ($0.type, $0) })
        #expect(Set(habits.keys) == [.endStretch, .endRise, .midPause])
        #expect(Set(habits[.endStretch]?.occurrences.map(\.startIdx) ?? []) == [marks.end1, marks.end3])
        #expect(Set(habits[.endRise]?.occurrences.map(\.startIdx) ?? []) == [marks.end2, marks.end3])
        #expect(habits[.midPause]?.count == 2)
        #expect(habits[.midPause]?.firstIdx == index("오늘", in: SpeechSynth.demoScript) + 1)
    }

    @Test func separatesExpectedPauses() throws {
        let result = try #require(Self.demo)
        let habitual = result.pauses.filter(\.isHabit)
        #expect(habitual.count == 2)
        #expect(habitual.allSatisfy { (590...760).contains($0.durationMs) })
        #expect(habitual.allSatisfy { !$0.expected && $0.habitType == .midPause })
        #expect(habitual.allSatisfy { $0.relativeLength > 1.2 })
        let sentence = result.pauses.filter { $0.boundary == .sentence }
        #expect(!sentence.isEmpty && sentence.allSatisfy { $0.expected && !$0.isHabit })
        #expect(abs((result.summary.typicalPauseMs ?? 0) - 450) <= 60)
    }

    @Test func levelsPitchAndSpeed() throws {
        let result = try #require(Self.demo)
        let marks = SpeechSynth.demoMarks
        let top = try syllable(result, marks.end2)
        // 문장 끝 글자는 +5반음이어도 '높음' 표시 대상에서 빠진다(5단계). 측정값과 말끝 올림 판정은 그대로다.
        #expect(top.pitchLevel == 5 && abs((top.pitchSt ?? 0) - 5) < 0.7 && top.isHabit)
        let stretched = try syllable(result, marks.end1)
        #expect(stretched.stretch && stretched.stretchRatio > 2)
        #expect(result.syllables.count(where: { $0.pitchLevel == 4 }) > result.syllables.count / 2)
        #expect(result.phrases.first { $0.startIdx == marks.start4 }?.speedLabel == .fast)
        #expect(result.phrases.contains { $0.speedLabel == .normal })
        #expect(result.summary.alignedRatio == 1)
        #expect(abs((result.summary.medianPitchHz ?? 0) - 120) <= 6)
        #expect(result.unclearRanges.isEmpty && result.disfluencies.isEmpty)
        #expect(result.spokenText == SpeechSynth.demoScript && result.spokenDifferences.isEmpty)
        #expect(!result.warnings.contains("SCRIPT_DEVIATION"))
    }

    @Test func hidesLowAndEndMarks() throws {
        let result = try #require(Self.demo)
        #expect(result.syllables.allSatisfy { $0.pitchLevel > 2 })
        let ends = Set(ScriptText.parse(SpeechSynth.demoScript).filter(\.isSentenceEnd).map(\.idx))
        #expect(result.syllables.filter { ends.contains($0.idx) }.allSatisfy { $0.pitchLevel < 6 })

        var config = SpeechConfig.default
        config.pitchMarkSentenceEnd = true
        config.pitchMarkLow = true
        let marked = try Self.demoSynth.analyze(script: SpeechSynth.demoScript, config: config)
        #expect([6, 7].contains(try syllable(marked, SpeechSynth.demoMarks.end2).pitchLevel))
    }

    @Test func reportsSkipped() throws {
        let spoken = "저는 오늘 발표를 시작하겠습니다. 이번 주제는 문화입니다."
        let result = try run(script, spoken: spoken).result
        let start = index("결제", in: script)
        #expect(result.mismatchedRanges == [IdxRange(startIdx: start, endIdx: start + 1)])
        #expect(result.unclearRanges.map(\.reason) == [.skipped])
        #expect(result.unclearRanges.first?.startIdx == start && result.unclearRanges.first?.endIdx == start + 1)
        let missed = result.syllables.filter { !$0.aligned }
        #expect(missed.map(\.char) == ["결", "제"] && !missed.contains { $0.inferred })
    }

    @Test func locatesMumbled() throws {
        let (result, synth) = try run(script) { $0.filter { $0.text != "결제" } }
        let start = index("결제", in: script)
        for idx in [start, start + 1] {
            let guessed = try syllable(result, idx)
            let truth = try #require(synth.truth.first { $0.idx == idx })
            #expect(guessed.inferred && !guessed.aligned && !guessed.stretch)
            #expect(abs(Double(guessed.startMs) - truth.startMs) < 100)
        }
        #expect(result.unclearRanges.map(\.reason) == [.lowRecognition])
        #expect(result.unclearRanges.first?.startIdx == start && result.unclearRanges.first?.endIdx == start + 1)
    }

    @Test func locatesMisheardSyllable() throws {
        let swap: ([WordTiming]) -> [WordTiming] = { words in
            words.map { $0.text == "발표를" ? WordTiming(text: "발포를", start: $0.start, end: $0.end, prob: $0.prob) : $0 }
        }
        let (result, synth) = try run(script, words: swap)
        let idx = index("표", in: script)
        let misheard = try syllable(result, idx)
        let truth = try #require(synth.truth.first { $0.idx == idx })
        #expect(try syllable(result, idx - 1).aligned && syllable(result, idx + 1).aligned)
        #expect(misheard.inferred && !misheard.aligned)
        #expect(abs(Double(misheard.startMs) - truth.startMs) < 100)
        #expect(result.unclearRanges.isEmpty)

        var strict = SpeechConfig.default
        strict.lowRecognitionMinConf = 0
        let unclear = try run(script, config: strict, words: swap).result.unclearRanges
        #expect(unclear.map(\.reason) == [.lowRecognition])
        #expect(unclear.first?.startIdx == idx && unclear.first?.endIdx == idx)
    }

    @Test func ignoresPenultimatePeak() throws {
        let text = "하나입니다. 둘입니다. 셋입니다. 넷입니다."
        var overrides: [Int: SpeechSynth.Override] = [:]
        for word in ["하나입니다", "둘입니다", "셋입니다"] {
            let penultimate = index(word, in: text) + word.unicodeScalars.count - 2
            overrides[penultimate] = SpeechSynth.Override(f0: SpeechSynth.raisedF0)
        }
        let result = try run(text, overrides: overrides).result
        #expect(!result.habits.contains { $0.type == .endRise })
    }

    @Test func reportsLowVolume() throws {
        let text = script + " 먼저 배경을 설명하겠습니다."
        let end = index("시작하겠습니다", in: text) + 6
        var quiet: [Int: SpeechSynth.Override] = [:]
        for idx in (end - 2)...end { quiet[idx] = SpeechSynth.Override(amp: 0.04) }
        let result = try run(text, overrides: quiet).result
        // 작은 소리는 발음이 흐린 것과 다르다. 기본은 불분명으로 내지 않고 음절 표시만 남긴다.
        #expect(!result.unclearRanges.contains { $0.reason == .lowVolume })
        let faded = try syllable(result, end)
        #expect(faded.lowVolume && (faded.volumeDb ?? 0) < -14)
        #expect(try !syllable(result, index("저", in: text)).lowVolume)

        var config = SpeechConfig.default
        config.lowVolumeIsUnclear = true
        let unclear = try run(text, overrides: quiet, config: config).result.unclearRanges
        let low = unclear.filter { $0.reason == .lowVolume }
        #expect(low.count == 1 && low.first?.endIdx == end && (low.first?.startIdx ?? end) <= end - 1)
    }

    @Test func splitsUnclearBySentence() throws {
        let text = script + " 먼저 배경을 설명하겠습니다."
        let end = index("시작하겠습니다", in: text) + 6
        var quiet: [Int: SpeechSynth.Override] = [:]
        for idx in [end - 1, end, end + 3, end + 4] { quiet[idx] = SpeechSynth.Override(amp: 0.04) }
        var config = SpeechConfig.default
        config.lowVolumeIsUnclear = true
        let unclear = try run(text, overrides: quiet, config: config).result.unclearRanges
        let low = unclear.filter { $0.reason == .lowVolume }
        #expect(low.count == 2 && low.first?.endIdx == end && (low.last?.startIdx ?? 0) > end)
    }

    @Test func reportsLowProbability() throws {
        let doubt: ([WordTiming]) -> [WordTiming] = { words in
            words.map { WordTiming(text: $0.text, start: $0.start, end: $0.end, prob: $0.text == "결제" ? 0.2 : 0.95) }
        }
        // 대본과 같은 글자로 알아들었는데 확신만 낮으면 근거를 절반만 인정하고, 하한(0.65)에 못 미치면 내지 않는다.
        #expect(try !run(script, words: doubt).result.unclearRanges.contains { $0.reason == .lowRecognition })
        var loose = SpeechConfig.default
        loose.lowRecognitionMinConf = 0
        let ranges = try run(script, config: loose, words: doubt).result.unclearRanges
        let start = index("결제", in: script)
        #expect(ranges == [UnclearRange(startIdx: start, endIdx: start + 1, reason: .lowRecognition, confidence: 0.4)])
    }

    @Test func detectsPauseHabits() throws {
        let words = ["하나입니다", "둘입니다", "셋입니다", "넷입니다", "다섯입니다", "여섯입니다", "일곱입니다"]
        let ends = words.map { index($0, in: counting) + $0.unicodeScalars.count - 1 }

        var result = try run(counting, gaps: [ends[0]: 1500, ends[2]: 1500]).result
        let long = try #require(result.habits.first { $0.type == .longPause })
        #expect(long.count == 2 && Set(long.occurrences.map(\.startIdx)) == [ends[0], ends[2]])
        #expect(!result.habits.contains { $0.type == .midPause })
        let longPauses = result.pauses.filter { $0.habitType == .longPause }
        #expect(longPauses.count == 2 && longPauses.allSatisfy { $0.expected && $0.relativeLength >= 2 })

        result = try run(counting, gaps: [ends[1]: 20, ends[3]: 20]).result
        let tight = try #require(result.habits.first { $0.type == .noBreak })
        #expect(tight.count == 2 && Set(tight.occurrences.map(\.startIdx)) == [ends[1], ends[3]])

        let quiet = [ends[0]: SpeechSynth.Override(amp: 0.04), ends[4]: SpeechSynth.Override(amp: 0.04)]
        result = try run(counting, overrides: quiet).result
        #expect(result.habits.first { $0.type == .endFade }?.count == 2)
    }

    @Test func rejectsLowCoverage() {
        let other = [WordTiming(text: "전혀", start: 0.5, end: 0.9), WordTiming(text: "다른", start: 1.0, end: 1.4)]
        #expect(errorCode { try run(script) { _ in other }.result } == .alignmentLowCoverage)
    }

    @Test func rejectsBadInput() {
        let words = [WordTiming(text: "안녕하세요", start: 0.1, end: 0.4)]
        let short = [Float](repeating: 0, count: 16000)
        let greeting = "안녕하세요 반갑습니다"
        #expect(errorCode { try SpeechEngine.analyze(samples: short, script: "", words: words) } == .emptyScript)
        #expect(errorCode { try SpeechEngine.analyze(samples: short, script: "네 hi 3", words: words) } == .emptyScript)
        let tooShort = errorCode { try SpeechEngine.analyze(samples: short, script: greeting, words: words) }
        #expect(tooShort == .audioTooShort)
        let long = [Float](repeating: 0, count: 16000 * 600 + 1)
        #expect(errorCode { try SpeechEngine.analyze(samples: long, script: greeting, words: words) } == .audioTooLong)
        let two = short + short
        #expect(errorCode { try SpeechEngine.analyze(samples: two, script: greeting, words: []) } == .noSpeech)
        let broken = [WordTiming(text: "안녕하세요", start: .nan, end: 0.4)]
        #expect(errorCode { try SpeechEngine.analyze(samples: two, script: greeting, words: broken) } == .internal)
        do {
            _ = try SpeechEngine.analyze(samples: short, script: greeting, words: words)
        } catch {
            #expect((error as? AnalysisError)?.message == "녹음이 너무 짧습니다 (1.0초).")
        }
    }

    @Test func findsStraySound() throws {
        let (result, synth, after, next) = try runInsert(SpeechSynth.Insert(dur: 300))
        let stray = result.disfluencies.filter { $0.type == .straySound }
        #expect(stray.count == 1 && stray.first?.beforeIdx == next)
        #expect(abs((stray.first.map { $0.endMs - $0.startMs } ?? 0) - 300) < 80)
        #expect(!result.pauses.contains { $0.afterIdx == after })
        let before = try syllable(result, after)
        let truth = try #require(synth.truth.first { $0.idx == after })
        #expect(!before.stretch && abs(Double(before.endMs) - truth.endMs) < 80)
    }

    @Test func ignoresBreathNoise() throws {
        let (result, _, after, _) = try runInsert(SpeechSynth.Insert(dur: 300, noise: true, amp: 0.05))
        #expect(result.disfluencies.isEmpty)
        #expect(result.pauses.contains { $0.afterIdx == after })
    }

    @Test func reportsFillerWord() throws {
        let (result, _, after, next) = try runInsert(SpeechSynth.Insert(dur: 250)) {
            WordTiming(text: "음", start: $0 / 1000, end: ($0 + 250) / 1000, prob: 0.8)
        }
        #expect(result.disfluencies.map(\.type) == [.filler])
        #expect(result.disfluencies.first?.beforeIdx == next && result.disfluencies.first?.text == "음")
        #expect(!result.pauses.contains { $0.afterIdx == after })
    }

    @Test func reportsRepeatedWord() throws {
        let result = try runInsert(SpeechSynth.Insert(dur: 250)) {
            WordTiming(text: "오늘", start: $0 / 1000, end: ($0 + 250) / 1000, prob: 0.8)
        }.result
        #expect(result.disfluencies.contains { $0.type == .repeat && $0.text == "오늘" })
    }

    @Test func addsExtraWord() throws {
        let result = try runInsert(SpeechSynth.Insert(dur: 250)) {
            WordTiming(text: "정말로요", start: $0 / 1000, end: ($0 + 250) / 1000, prob: 0.9)
        }.result
        #expect(result.spokenText.contains("오늘 정말로요 발표를"))
        #expect(result.spokenDifferences.map(\.kind) == [.added])
        #expect(result.disfluencies.isEmpty)
    }

    @Test func showsReplacedWord() throws {
        let spoken = "저는 오늘 발표를 시작하겠습니다. 이번 주제는 신용카드 문화입니다."
        let result = try run(script, spoken: spoken).result
        let start = index("결제", in: script)
        #expect(result.spokenText == spoken)
        #expect(result.spokenDifferences == [
            SpokenDifference(kind: .replaced, startIdx: start, endIdx: start + 3, spoken: "신용카드", scriptText: "결제"),
        ])
        for idx in start..<(start + 4) {
            let replaced = try syllable(result, idx)
            #expect(replaced.aligned && replaced.pitchHz != nil)
        }
        #expect(result.unclearRanges.isEmpty)
    }

    @Test func analyzesParaphrase() throws {
        let text = "저는 오늘 발표를 시작하겠습니다. 먼저 배경을 설명하여 이렇게 됐습니다. 감사합니다."
        let spoken = "저는 오늘 발표를 시작하겠습니다. 먼저 배경을 설명하다 보니 이렇게 될 수도 있습니다. 감사합니다."
        let result = try run(text, spoken: spoken).result
        #expect(result.spokenText == spoken)
        #expect(result.summary.alignedRatio > 0.97)
        #expect(result.unclearRanges.isEmpty)
        #expect(result.syllables.allSatisfy { $0.pitchHz != nil })
    }

    @Test func analyzesAddedSentence() throws {
        let text = "저는 오늘 발표를 시작하겠습니다. 감사합니다."
        let added = "사실 이 주제는 제가 오래 고민했던 내용입니다."
        let result = try run(text, spoken: "저는 오늘 발표를 시작하겠습니다. " + added + " 감사합니다.").result
        #expect(result.spokenText.contains(added))
        #expect(result.spokenDifferences.map(\.kind) == [.added])
        #expect(result.disfluencies.isEmpty)
        let start = index("사실", in: result.spokenText)
        #expect(result.syllables.filter { $0.idx >= start }.allSatisfy { $0.aligned })
        #expect(!result.pauses.contains { $0.durationMs > 2000 })
    }

    @Test func warnsRewrittenSpeech() throws {
        let text = "저는 오늘 결제 문화의 변화를 설명하고 앞으로의 과제를 말씀드리겠습니다. 감사합니다."
        let spoken = "오늘은 돈을 내는 방식이 요즘 어떻게 달라졌는지 이야기해 보겠습니다. 감사합니다."
        let result = try run(text, spoken: spoken).result
        #expect(result.spokenText.contains(spoken))
        #expect(result.warnings.contains("SCRIPT_DEVIATION"))
        #expect((result.summary.scriptMatchRatio ?? 1) < 0.7)
        #expect(result.summary.alignedRatio > 0.9)
    }

    @Test func keepsSimilarSound() throws {
        let result = try run(script) { words in
            words.map { $0.text == "결제" ? WordTiming(text: "결재", start: $0.start, end: $0.end, prob: $0.prob) : $0 }
        }.result
        #expect(result.spokenDifferences.isEmpty)
    }

    @Test func keepsDoubtfulRecognition() throws {
        let (result, synth) = try run(script) { words in
            words.map { $0.text == "결제" ? WordTiming(text: "계약", start: $0.start, end: $0.end, prob: 0.6) : $0 }
        }
        let start = index("결제", in: script)
        #expect(result.spokenText == script && result.spokenDifferences.isEmpty)
        for idx in [start, start + 1] {
            let located = try syllable(result, idx)
            let truth = try #require(synth.truth.first { $0.idx == idx })
            #expect(located.inferred && !located.aligned)
            #expect(abs(Double(located.startMs) - truth.startMs) < 120)
        }
        let unclear = try #require(result.unclearRanges.first { $0.startIdx == start })
        #expect(unclear.reason == .lowRecognition && unclear.confidence >= 0.5)
    }

    @Test func locatesMergedWord() throws {
        let text = "저는 오늘 소리 내어 읽겠습니다. 이번 주제는 결제 문화입니다."
        let (result, synth) = try run(text) { words in
            var merged: [WordTiming] = []
            for word in words {
                if word.text == "내어", let previous = merged.popLast() {
                    merged.append(WordTiming(text: "소리를", start: previous.start, end: word.end, prob: 0.9))
                } else {
                    merged.append(word)
                }
            }
            return merged
        }
        let idx = index("내어", in: text)
        let truth = try #require(synth.truth.first { $0.idx == idx })
        let located = try syllable(result, idx)
        #expect(!result.unclearRanges.contains { $0.reason == .skipped })
        #expect(located.inferred && abs(Double(located.startMs) - truth.startMs) < 200)
    }

    @Test func keepsScriptIndices() throws {
        let text = "저는 😀오늘 발표를\r\n시작하겠습니다. AI 3.5점 주제는 결제 문화입니다."
        let result = try run(text).result
        let scalars = Array(text.unicodeScalars)
        #expect(result.spokenText == text)
        #expect(result.syllables.allSatisfy { String(scalars[$0.idx]) == $0.char })
        let hangul = result.syllables.filter { $0.char.unicodeScalars.allSatisfy(\.isHangulSyllable) }
        #expect(hangul.count == 25 && hangul.allSatisfy { $0.aligned })
        #expect(result.syllables.map(\.char).joined() == "저는오늘발표를시작하겠습니다AI35점주제는결제문화입니다")
    }
}
