//
//  WordRetiming.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

// 글자 수에 비해 말이 안 되게 짧은 시간을 받은 단어는 시각을 믿을 수 없다.
// 앞뒤 단어와 묶어 그 구간의 소리가 있는 부분을 글자 수에 비례해 다시 나눈다.
nonisolated enum WordRetiming {
    static func retimeDegenerate(_ words: [TimedWord], db: [Double], config: SpeechConfig) -> [TimedWord] {
        guard !db.isEmpty, !words.isEmpty else { return words }
        let threshold = AcousticFeatures.speechThreshold(db)
        var out = words
        let count = out.count

        func isDegenerate(_ word: TimedWord, _ chars: Int) -> Bool {
            (word.end.value - word.start.value) * 1000 < Double(config.minWordMsPerChar * chars)
        }

        var index = 0
        while index < count {
            let chars = out[index].hangulCount
            if chars == 0 || !isDegenerate(out[index], chars) {
                index += 1
                continue
            }
            let low = index > 0 ? index - 1 : index
            var high = index + 1 < count ? index + 1 : index
            while high + 1 < count && (out[high].hangulCount == 0 || isDegenerate(out[high], out[high].hangulCount)) {
                high += 1
            }
            let group = Array(out[low...high])
            let counts = group.map(\.hangulCount)
            let segments = Alignment.voicedSegments(
                db: db,
                threshold: threshold,
                from: config.frame(ms: group[0].start.value * 1000),
                to: config.frame(ms: group[group.count - 1].end.value * 1000),
                config: config
            )
            let totalChars = Double(counts.reduce(0, +))
            if segments.isEmpty || totalChars == 0 {
                index = high + 1
                continue
            }
            let lengths = segments.map { $0.end - $0.start }
            let totalVoiced = Double(lengths.reduce(0, +))
            let cumulative = lengths.reduce(into: [0.0]) { $0.append($0[$0.count - 1] + Double($1)) }

            func frame(at voiced: Double, isEnd: Bool) -> PyNumber {
                let found = NumPy.searchSorted(cumulative, voiced, right: !isEnd) - 1
                let segment = min(max(found, 0), segments.count - 1)
                let offset = PyNumber(voiced - cumulative[segment], isNumpy: true)
                let clamped = PyNumber.min(PyNumber.max(offset, .zero), PyNumber(lengths[segment]))
                return PyNumber(segments[segment].start) + clamped
            }

            var accumulated = 0
            for (offset, word) in group.enumerated() where counts[offset] != 0 {
                let from = totalVoiced * Double(accumulated) / totalChars
                let to = totalVoiced * Double(accumulated + counts[offset]) / totalChars
                accumulated += counts[offset]
                var retimed = word
                retimed.start = frame(at: from, isEnd: false) * Double(config.hopMs) / 1000
                retimed.end = frame(at: to, isEnd: true) * Double(config.hopMs) / 1000
                out[low + offset] = retimed
            }
            index = high + 1
        }
        return out
    }
}
