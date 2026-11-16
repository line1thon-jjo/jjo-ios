//
//  SpeechSynth.swift
//  jjo-ios-Tests
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation
@testable import jjo_ios

// 정답을 아는 합성 음성. 글자마다 지정한 길이·음높이·크기의 소리를 이어 붙여 실제 목소리 없이 분석 로직을 검증한다.
nonisolated struct SpeechSynth: Sendable {
    nonisolated struct Override: Sendable {
        var dur: Double?
        var f0: Double?
        var amp: Float = 0.3
    }

    nonisolated struct Insert: Sendable {
        var pre = 100.0
        var dur = 250.0
        var post = 100.0
        var noise = false
        var f0 = 140.0
        var amp: Float = 0.25
    }

    nonisolated struct Truth: Sendable {
        let idx: Int
        let startMs: Double
        let endMs: Double
        let f0: Double
    }

    static let sampleRate = 16000.0
    static let demoScript = "저는 오늘 발표를 시작하겠습니다. 이번 주제는 결제 문화입니다. "
        + "먼저 배경을 설명하겠습니다. 감사합니다."
    static let raisedF0 = 120 * pow(2.0, 5.0 / 12.0)

    var samples: [Float] = []
    var truth: [Truth] = []
    var voiced: [Truth] = []
    var units: [ScriptUnit] = []

    init(
        _ script: String,
        baseMs: Double = 150,
        baseF0: Double = 120,
        overrides: [Int: Override] = [:],
        gaps: [Int: Double] = [:],
        inserts: [Int: Insert] = [:],
        leadMs: Double = 400,
        tailMs: Double = 400
    ) {
        units = ScriptText.parse(script).filter(\.isHangul)
        var noise = NoiseGenerator(seed: 1)
        var time = leadMs
        appendSilence(leadMs)
        for (position, unit) in units.enumerated() {
            let override = overrides[unit.idx] ?? Override()
            let duration = override.dur ?? baseMs * (unit.hasBatchim ? 1.2 : 1.0)
            let f0 = override.f0 ?? baseF0 * (1 + 0.03 * sin(Double(position)))
            samples += Self.burst(f0: f0, durationMs: duration, amp: override.amp)
            let sound = Truth(idx: unit.idx, startMs: time, endMs: time + duration, f0: f0)
            truth.append(sound)
            voiced.append(sound)
            time += duration
            let isLast = position == units.count - 1
            let gap = isLast ? 0 : gaps[unit.idx] ?? Self.defaultGap(unit.boundaryAfter)
            appendSilence(gap)
            time += gap
            if let insert = inserts[unit.idx], !isLast {
                appendSilence(insert.pre)
                if insert.noise {
                    let count = Int(Self.sampleRate * insert.dur / 1000)
                    samples += (0..<count).map { _ in Float(noise.next()) * insert.amp }
                } else {
                    samples += Self.burst(f0: insert.f0, durationMs: insert.dur, amp: insert.amp)
                    let start = time + insert.pre
                    voiced.append(Truth(idx: -1, startMs: start, endMs: start + insert.dur, f0: insert.f0))
                }
                appendSilence(insert.post)
                time += insert.pre + insert.dur + insert.post
            }
        }
        appendSilence(tailMs)
        var hiss = NoiseGenerator(seed: 0)
        samples = samples.map { $0 + Float(hiss.next() * 0.001) }
    }

    var words: [WordTiming] {
        let byIdx = Dictionary(uniqueKeysWithValues: truth.map { ($0.idx, $0) })
        var words: [WordTiming] = []
        var first = 0
        while first < units.count {
            var last = first
            while last + 1 < units.count && units[last + 1].wordId == units[first].wordId { last += 1 }
            guard let head = byIdx[units[first].idx], let tail = byIdx[units[last].idx] else { break }
            let start = head.startMs - 25
            var end = tail.endMs + 25
            if last + 1 < units.count, let following = byIdx[units[last + 1].idx] {
                let next = following.startMs - 10
                if next - end > 100 { end = min(end + 300, next) }
            }
            let text = units[first...last].map(\.char).text
            words.append(WordTiming(text: text, start: start / 1000, end: end / 1000))
            first = last + 1
        }
        return words
    }

    var pitch: SpeechEngine.PitchProvider {
        let voiced = voiced
        let frameCount = Int(Double(samples.count) / Self.sampleRate * 100) + 1
        return { _, _, timeStep, _, _ in
            let times = (0..<frameCount).map { Double($0) * timeStep }
            let frequencies = times.map { time in
                voiced.first { $0.startMs + 10 <= time * 1000 && time * 1000 < $0.endMs - 10 }?.f0 ?? 0
            }
            return PitchTrack(times: times, frequencies: frequencies)
        }
    }

    func analyze(
        script: String,
        words: [WordTiming]? = nil,
        config: SpeechConfig = .default
    ) throws -> AnalysisResult {
        try SpeechEngine.analyze(
            samples: samples,
            script: script,
            words: words ?? self.words,
            config: config,
            pitch: pitch
        )
    }

    static func demo() -> SpeechSynth {
        let marks = demoMarks
        var overrides: [Int: Override] = [
            marks.end1: Override(dur: 450),
            marks.end2: Override(dur: 150, f0: raisedF0),
            marks.end3: Override(dur: 450, f0: raisedF0),
        ]
        for idx in marks.start4...marks.end4 { overrides[idx] = Override(dur: 100) }
        let gaps = [index(of: "오늘", in: demoScript) + 1: 700.0, index(of: "주제는", in: demoScript) + 2: 650.0]
        return SpeechSynth(demoScript, overrides: overrides, gaps: gaps)
    }

    static var demoMarks: (end1: Int, end2: Int, end3: Int, end4: Int, start4: Int) {
        let script = demoScript
        return (
            index(of: "겠습니다", in: script) + 3,
            index(of: "문화입니다", in: script) + 4,
            index(of: "겠습니다", in: script, nth: 1) + 3,
            index(of: "감사합니다", in: script) + 4,
            index(of: "감사합니다", in: script)
        )
    }

    static func index(of part: String, in text: String, nth: Int = 0) -> Int {
        let scalars = Array(text.unicodeScalars)
        let needle = Array(part.unicodeScalars)
        var seen = 0
        for start in 0...(scalars.count - needle.count) {
            guard scalars[start..<(start + needle.count)].elementsEqual(needle) else { continue }
            if seen == nth { return start }
            seen += 1
        }
        return -1
    }

    private static func defaultGap(_ boundary: ScriptBoundary) -> Double {
        switch boundary {
        case .none: 0
        case .word: 60
        case .comma: 250
        case .line: 300
        case .sentence: 450
        }
    }

    private static func burst(f0: Double, durationMs: Double, amp: Float) -> [Float] {
        let count = Int(sampleRate * durationMs / 1000)
        var phase = 0.0
        return (0..<count).map { index in
            phase += 2 * Double.pi * f0 / sampleRate
            let signal = (1...5).reduce(0.0) { $0 + sin(Double($1) * phase) / Double($1) }
            let position = count > 1 ? Double(index) / Double(count - 1) : 0
            let envelope = 0.25 + 0.75 * pow(sin(Double.pi * position), 0.6)
            return Float(Double(amp) * signal * envelope)
        }
    }

    private mutating func appendSilence(_ durationMs: Double) {
        samples += [Float](repeating: 0, count: Int(Self.sampleRate * durationMs / 1000))
    }
}

nonisolated struct NoiseGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed &+ 0x9E37_79B9_7F4A_7C15
    }

    mutating func next() -> Double {
        let first = max(uniform(), .leastNonzeroMagnitude)
        return (-2 * log(first)).squareRoot() * cos(2 * Double.pi * uniform())
    }

    private mutating func uniform() -> Double {
        state &+= 0x9E37_79B9_7F4A_7C15
        var mixed = state
        mixed = (mixed ^ (mixed >> 30)) &* 0xBF58_476D_1CE4_E5B9
        mixed = (mixed ^ (mixed >> 27)) &* 0x94D0_49BB_1331_11EB
        mixed ^= mixed >> 31
        return Double(mixed >> 11) / Double(1 << 53)
    }
}
