//
//  AcousticFeatures.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated enum AcousticFeatures {
    static func energyDb(_ samples: [Float], config: SpeechConfig) -> [Double] {
        let hop = Int(Double(config.sampleRate * config.hopMs) / 1000)
        let window = Int(Double(config.sampleRate) * 0.025)
        let pad = window / 2
        let padded = samples.count + 2 * pad
        guard hop > 0, padded >= window else { return [] }
        let frameCount = (padded - window) / hop + 1

        var squares = [Double](repeating: 0, count: window)
        var db = [Double](repeating: 0, count: frameCount)
        samples.withUnsafeBufferPointer { source in
            squares.withUnsafeMutableBufferPointer { buffer in
                for frame in 0..<frameCount {
                    let start = frame * hop - pad
                    for offset in 0..<window {
                        let index = start + offset
                        let value = index >= 0 && index < source.count ? Double(source[index]) : 0
                        buffer[offset] = value * value
                    }
                    let rms = (NumPy.pairwiseSum(UnsafeBufferPointer(buffer)) / Double(window)).squareRoot() + 1e-8
                    db[frame] = 20 * log10(rms)
                }
            }
        }
        guard db.count >= 3 else { return db }

        // numpy(arm64) 의 3점 평균은 곱과 덧셈을 한 번에 반올림(FMA)한다. 같은 방식이어야 마지막 자리까지 같다.
        let third = 1.0 / 3.0
        return db.indices.map { frame in
            let previous = db[max(frame - 1, 0)]
            let next = db[min(frame + 1, db.count - 1)]
            return (previous * third).addingProduct(db[frame], third).addingProduct(next, third)
        }
    }

    // 소리 사이에 낀 아주 짧은 잡음(입 소리, 클릭)은 앞뒤가 모두 충분히 조용하면 무음으로 취급한다.
    static func suppressBlips(_ db: [Double], config: SpeechConfig) -> [Double] {
        guard !db.isEmpty else { return db }
        let threshold = speechThreshold(db)
        let voiced = db.map { $0 > threshold }
        let count = db.count
        var out = db
        let maxLength = config.frame(ms: Double(config.blipMs))
        let minGap = config.frame(ms: Double(config.blipGapMs))
        var index = 0
        while index < count {
            if !voiced[index] {
                index += 1
                continue
            }
            var end = index
            while end < count && voiced[end] { end += 1 }
            if end - index <= maxLength {
                var left = index
                while left > 0 && !voiced[left - 1] { left -= 1 }
                var right = end
                while right < count && !voiced[right] { right += 1 }
                let leftGap = left > 0 ? index - left : minGap
                let rightGap = right < count ? right - end : minGap
                if leftGap >= minGap && rightGap >= minGap {
                    for frame in index..<end { out[frame] = threshold - 10.0 }
                }
            }
            index = end
        }
        return out
    }

    static func speechThreshold(_ db: [Double]) -> Double {
        let sorted = db.sorted()
        let floor = NumPy.percentile(sorted: sorted, 5)
        let peak = NumPy.percentile(sorted: sorted, 95)
        return max(floor + 0.3 * (peak - floor), peak - 40.0)
    }

    // 인식기의 어절 시각은 앞 어절 끝=뒤 어절 시작으로 붙어 있어 쉼이 어절 안으로 번진다.
    // 에너지에서 실제 무음 구간을 찾아 앞 음절의 끝과 뒤 음절의 시작을 무음 경계에 맞춘다.
    @discardableResult
    static func snapToSilence(_ syllables: [TimedSyllable], db: [Double], config: SpeechConfig) -> Int {
        guard !db.isEmpty else { return 0 }
        let threshold = speechThreshold(db)
        let minFrames = config.frame(ms: Double(config.pauseMinMs))
        var runs: [(start: Double, end: Double)] = []
        var start: Int?
        for (frame, level) in db.enumerated() {
            let quiet = level < threshold
            if quiet && start == nil {
                start = frame
            } else if !quiet, let begun = start {
                if frame - begun >= minFrames {
                    runs.append((Double(begun * config.hopMs), Double(frame * config.hopMs)))
                }
                start = nil
            }
        }

        func middle(_ syllable: TimedSyllable) -> Double {
            (syllable.startMs.value + syllable.endMs.value) / 2
        }

        let timed = syllables.filter { $0.unit.isHangul && $0.timed }
        let minSyllable = Double(config.minSyllableMs)
        let reach = 300.0
        var snapped = 0
        for (runStart, runEnd) in runs {
            guard let a = timed.last(where: { middle($0) <= runStart }) else { continue }
            let found = timed.first { $0.startMs.value >= a.startMs.value && $0 !== a && middle($0) > runStart }
            guard let b = found else { continue }
            let offset = runStart - a.endMs.value
            if !(-reach <= offset && offset <= reach) { continue }
            if b.startMs.value < runEnd && !fits(syllables, b, config: config, low: runEnd) { continue }
            if a.endMs.value > runStart && !fits(syllables, a, config: config, high: runStart) { continue }
            if runStart - a.startMs.value < minSyllable / 2 && a.endMs.value <= runStart { continue }
            if a.endMs.value > runStart, let group = a.group {
                squeeze(syllables, group: group, high: runStart)
            }
            if a.endMs.value > runStart {
                a.endMs = PyNumber(runStart)
            } else {
                // 음절 길이(늘임 판단)는 그대로 두고, 쉼이 시작되는 시각만 실제 무음 시작으로 기록한다.
                a.silStart = PyNumber(runStart)
            }
            a.snapEnd = true
            if b.startMs.value < runEnd {
                if let group = b.group {
                    squeeze(syllables, group: group, low: runEnd)
                }
                b.startMs = PyNumber.max(b.startMs, PyNumber(runEnd))
                b.snapStart = true
            } else if abs(b.startMs.value - runEnd) <= reach {
                b.startMs = PyNumber(runEnd)
                b.snapStart = true
            }
            snapped += 1
        }
        return snapped
    }

    static func pitchTrack(
        _ samples: [Float],
        config: SpeechConfig,
        frameCount: Int,
        provider: SpeechEngine.PitchProvider
    ) -> [Double] {
        let sampleRate = Double(config.sampleRate)
        let timeStep = Double(config.hopMs) / 1000
        // 사람마다 목소리 높이가 달라서 고정 범위로 한 번만 재면 한 옥타브씩 튄다. 넓게 재서 평소 음높이를 알아낸 뒤 좁혀서 다시 잰다.
        var track = provider(samples, sampleRate, timeStep, config.pitchFloorHz, config.pitchCeilingHz)
        let voiced = track.frequencies.filter { $0 > 0 }.sorted()
        if voiced.count >= 20 {
            let floor = max(config.pitchFloorHz, config.pitchFloorRatio * NumPy.percentile(sorted: voiced, 25))
            let ceiling = min(config.pitchCeilingHz, config.pitchCeilingRatio * NumPy.percentile(sorted: voiced, 75))
            if ceiling > floor * 1.5 {
                track = provider(samples, sampleRate, timeStep, floor, ceiling)
            }
        }

        var f0 = [Double](repeating: .nan, count: frameCount)
        for (time, frequency) in zip(track.times, track.frequencies) {
            let position = (time * 1000 / Double(config.hopMs)).rounded(.toNearestOrEven)
            guard position >= 0, position < Double(frameCount) else { continue }
            f0[Int(position)] = frequency > 0 ? frequency : .nan
        }
        return f0
    }

    private static func members(_ syllables: [TimedSyllable], of syllable: TimedSyllable) -> [TimedSyllable] {
        guard let group = syllable.group else { return [syllable] }
        let found = syllables.filter { $0.group == group && $0.aligned }
        return found.isEmpty ? [syllable] : found
    }

    private static func fits(
        _ syllables: [TimedSyllable],
        _ syllable: TimedSyllable,
        config: SpeechConfig,
        low: Double? = nil,
        high: Double? = nil
    ) -> Bool {
        let group = members(syllables, of: syllable)
        let start = low ?? group[0].startMs.value
        let end = high ?? group[group.count - 1].endMs.value
        return end - start >= Double(group.count * config.minSyllableMs * 2) / 3
    }

    private static func squeeze(_ syllables: [TimedSyllable], group: Int, low: Double? = nil, high: Double? = nil) {
        let members = syllables.filter { $0.group == group && $0.aligned }
        guard let first = members.first, let last = members.last else { return }
        let groupStart = first.startMs
        let groupEnd = last.endMs
        let newStart = low.map { PyNumber($0) } ?? groupStart
        let newEnd = high.map { PyNumber($0) } ?? groupEnd
        if groupEnd.value <= groupStart.value || newEnd.value <= newStart.value { return }
        let scale = (newEnd - newStart) / (groupEnd - groupStart)
        for member in members {
            member.startMs = newStart + (member.startMs - groupStart) * scale
            member.endMs = newStart + (member.endMs - groupStart) * scale
        }
    }
}
