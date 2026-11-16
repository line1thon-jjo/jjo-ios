//
//  PauseDetector.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated enum PauseDetector {
    static func longestQuietMs(db: [Double], from: Double, to: Double, config: SpeechConfig) -> Double {
        let hop = Double(config.hopMs)
        let start = max(0, Int(PyNumber.floorDivide(from, by: hop)))
        let end = min(db.count, Int(PyNumber.floorDivide(to, by: hop)))
        guard end > start else { return 0 }
        let threshold = AcousticFeatures.speechThreshold(db)
        var best = 0
        var run = 0
        for level in db[start..<end] {
            run = level <= threshold ? run + 1 : 0
            best = max(best, run)
        }
        return Double(best * config.hopMs)
    }

    static func detect(
        _ syllables: [TimedSyllable],
        config: SpeechConfig,
        skipAfter: Set<Int> = [],
        db: [Double]? = nil
    ) -> (pauses: [Pause], typicalMs: Double) {
        var raw: [(syllable: TimedSyllable, gap: PyNumber)] = []
        let timed = syllables.filter { $0.unit.isHangul && $0.timed }
        // 한글 사이에 소리 내어 읽은 영문·숫자가 끼어 있으면 시각 차이는 무음이 아니다. 에너지로 쉼 길이를 직접 잰다.
        let spoken = syllables.filter { !$0.unit.isHangul && $0.unit.char.isPythonAlnum }.map(\.unit.idx).sorted()
        let minPause = Double(config.pauseMinMs)

        func spansSpoken(_ low: Int, _ high: Int) -> Bool {
            var first = 0
            var last = spoken.count
            while first < last {
                let middle = (first + last) / 2
                if spoken[middle] <= low {
                    first = middle + 1
                } else {
                    last = middle
                }
            }
            return first < spoken.count && spoken[first] < high
        }

        for (a, b) in zip(timed, timed.dropFirst()) {
            if spansSpoken(a.unit.idx, b.unit.idx) {
                guard let db, !skipAfter.contains(a.unit.idx) else { continue }
                let quiet = longestQuietMs(db: db, from: a.endMs.value, to: b.startMs.value, config: config)
                if quiet >= minPause { raw.append((a, PyNumber(quiet))) }
                continue
            }
            // 둘 다 추정 시각이어도 앞 끝·뒤 시작이 모두 무음 경계에 맞춰졌으면 쉼으로 본다.
            guard a.aligned || b.aligned || (a.snapEnd && b.snapStart) else { continue }
            if skipAfter.contains(a.unit.idx) { continue }
            let gap = b.startMs - (a.silStart ?? a.endMs)
            if gap.value >= minPause { raw.append((a, gap)) }
        }

        let expectedGaps = raw.filter { $0.syllable.unit.strength >= 2 }.map(\.gap.value)
        let typical = expectedGaps.count >= 3 ? NumPy.median(expectedGaps) : Double(config.typicalPauseDefaultMs)

        let pauses = raw.map { syllable, gap in
            Pause(
                afterIdx: syllable.unit.idx,
                durationMs: PyNumber.round(gap.value),
                boundary: syllable.unit.boundaryAfter.pauseBoundary,
                expected: syllable.unit.strength >= 2,
                relativeLength: (gap / typical).rounded(digits: 2)
            )
        }
        return (pauses, typical)
    }
}
