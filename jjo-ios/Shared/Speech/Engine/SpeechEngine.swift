//
//  SpeechEngine.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated enum SpeechEngine {
    typealias PitchProvider = @Sendable (
        _ samples: [Float],
        _ sampleRate: Double,
        _ timeStep: Double,
        _ floor: Double,
        _ ceiling: Double
    ) -> PitchTrack

    static func analyze(
        samples: [Float],
        script: String,
        words: [WordTiming],
        config: SpeechConfig = .default,
        pitch: PitchProvider = {
            PitchTracker.track(samples: $0, sampleRate: $1, timeStep: $2, floor: $3, ceiling: $4)
        }
    ) throws -> AnalysisResult {
        var units = ScriptText.parse(script)
        var hangulCount = units.count(where: \.isHangul)
        guard hangulCount >= 3 else {
            throw AnalysisError(code: .emptyScript, message: "분석할 대본(한글)이 너무 짧거나 비어 있습니다.")
        }

        let exactDurationMs = Double(samples.count * 1000) / Double(config.sampleRate)
        if exactDurationMs < Double(config.minAudioMs) {
            let seconds = String(format: "%.1f", exactDurationMs / 1000)
            throw AnalysisError(code: .audioTooShort, message: "녹음이 너무 짧습니다 (\(seconds)초).")
        }
        if exactDurationMs > Double(config.maxAudioS * 1000) {
            let seconds = String(format: "%.0f", exactDurationMs / 1000)
            throw AnalysisError(code: .audioTooLong, message: "녹음이 너무 깁니다 (\(seconds)초).")
        }
        guard !words.isEmpty else {
            throw AnalysisError(code: .noSpeech, message: "녹음에서 말소리를 인식하지 못했습니다.")
        }
        guard words.allSatisfy(isUsable) else {
            throw AnalysisError(code: .internal, message: "인식된 단어의 시각이 올바르지 않습니다.")
        }

        let samples = finite(samples)
        let timedWords = Numerals.normalize(words, script: script).map(TimedWord.init)
        let spoken = SpokenTextBuilder.build(script: script, units: units, words: timedWords, config: config)
        if !spoken.text.unicodeScalars.elementsEqual(script.unicodeScalars) {
            units = ScriptText.parse(spoken.text)
            let spokenHangul = units.count(where: \.isHangul)
            if spoken.matchRatio < config.minAlignCoverage
                && Double(spokenHangul) < config.minAlignCoverage * Double(hangulCount) {
                throw AnalysisError(
                    code: .alignmentLowCoverage,
                    message: "녹음에서 인식된 내용이 너무 적어 분석할 수 없습니다 (대본 일치율 \(percent(spoken.matchRatio)))."
                )
            }
            hangulCount = spokenHangul
        }

        let db = AcousticFeatures.suppressBlips(AcousticFeatures.energyDb(samples, config: config), config: config)
        let syllables = Alignment.align(units: units, words: timedWords, db: db, config: config)

        let aligned = syllables.filter { $0.unit.isHangul && $0.aligned }
        let alignedRatio = hangulCount > 0 ? Double(aligned.count) / Double(hangulCount) : 0
        if alignedRatio < config.minAlignCoverage {
            throw AnalysisError(
                code: .alignmentLowCoverage,
                message: "대본과 녹음이 많이 달라 분석할 수 없습니다 (일치율 \(percent(alignedRatio)))."
            )
        }

        AcousticFeatures.snapToSilence(syllables, db: db, config: config)
        let f0 = AcousticFeatures.pitchTrack(samples, config: config, frameCount: db.count, provider: pitch)
        let medianHz = SyllableFeatures.applyPitch(syllables, f0: f0, config: config)
        SyllableFeatures.applyVolume(syllables, db: db, config: config)
        SyllableFeatures.applyStretch(syllables, config: config)
        let disfluencies = Disfluencies.merge(
            byWords: Disfluencies.findInsertions(units: units, words: timedWords, config: config),
            bySound: Disfluencies.findStraySounds(syllables, db: db, f0: f0, config: config)
        )
        let skipAfter = Disfluencies.pausesWithDisfluency(syllables, found: disfluencies)
        var (pauses, typicalPauseMs) = PauseDetector.detect(syllables, config: config, skipAfter: skipAfter, db: db)
        let (phrases, articulationRate) = PhraseBuilder.build(syllables, config: config)
        let habits = Habits.detect(syllables, pauses: &pauses, config: config)
        let unclear = Clarity.detectUnclearRanges(syllables, config: config)

        var mismatched: [IdxRange] = []
        var run: [Int] = []
        for syllable in syllables {
            if syllable.unit.isHangul && !syllable.aligned {
                run.append(syllable.unit.idx)
            } else if let first = run.first, let last = run.last {
                mismatched.append(IdxRange(startIdx: first, endIdx: last))
                run = []
            }
        }
        if let first = run.first, let last = run.last {
            mismatched.append(IdxRange(startIdx: first, endIdx: last))
        }

        var warnings: [String] = []
        if alignedRatio < config.warnAlignCoverage { warnings.append("PARTIAL_ALIGNMENT") }
        if medianHz == nil { warnings.append("PITCH_UNAVAILABLE") }
        if spoken.matchRatio < config.scriptMatchWarn { warnings.append("SCRIPT_DEVIATION") }

        var averageRate = PyNumber.zero
        if let first = aligned.first, let last = aligned.last {
            let spanSeconds = (last.endMs - first.startMs) / 1000
            if spanSeconds.value > 0 { averageRate = Double(aligned.count) / spanSeconds }
        }

        return AnalysisResult(
            durationMs: PyNumber.round(exactDurationMs),
            spokenText: spoken.text,
            syllables: syllables.map(syllable),
            pauses: pauses,
            phrases: phrases,
            habits: habits,
            mismatchedRanges: mismatched,
            unclearRanges: unclear,
            disfluencies: disfluencies,
            spokenDifferences: spoken.differences,
            warnings: warnings,
            summary: AnalysisSummary(
                avgSyllablesPerSec: averageRate.rounded(digits: 2),
                articulationSyllablesPerSec: PyNumber.round(articulationRate, digits: 2),
                medianPitchHz: medianHz.map { PyNumber.round($0, digits: 1) },
                typicalPauseMs: PyNumber.round(typicalPauseMs),
                alignedRatio: PyNumber.round(alignedRatio, digits: 3),
                scriptMatchRatio: PyNumber.round(spoken.matchRatio, digits: 3)
            )
        )
    }

    private static func syllable(_ source: TimedSyllable) -> Syllable {
        Syllable(
            idx: source.unit.idx,
            char: String(source.unit.char),
            startMs: PyNumber.round(source.startMs.value),
            endMs: PyNumber.round(source.endMs.value),
            pitchHz: source.pitchHz.map { PyNumber.round($0, digits: 1) },
            pitchSt: source.pitchSt.map { PyNumber.round($0, digits: 1) },
            pitchLevel: source.pitchLevel,
            volumeDb: source.volumeDb.map { PyNumber.round($0, digits: 1) },
            lowVolume: source.lowVolume,
            stretch: source.stretch,
            stretchRatio: source.stretchRatio,
            aligned: source.aligned,
            inferred: source.inferred,
            confidence: source.confidence.map { PyNumber.round($0, digits: 2) },
            isHabit: !source.habitTypes.isEmpty,
            habitTypes: source.habitTypes
        )
    }

    private static func isUsable(_ word: WordTiming) -> Bool {
        let limit = 1e9
        return word.prob.isFinite && abs(word.start) <= limit && abs(word.end) <= limit
    }

    private static func percent(_ ratio: Double) -> String {
        String(format: "%.0f%%", ratio * 100)
    }

    private static func finite(_ samples: [Float]) -> [Float] {
        guard samples.contains(where: { !$0.isFinite }) else { return samples }
        let limit = Float.greatestFiniteMagnitude
        return samples.map { $0.isNaN ? 0 : min(max($0, -limit), limit) }
    }
}
