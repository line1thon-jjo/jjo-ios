//
//  Alignment.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated enum Alignment {
    typealias Segment = (start: Int, end: Int)

    static func align(
        units: [ScriptUnit],
        words: [TimedWord],
        db: [Double],
        config: SpeechConfig
    ) -> [TimedSyllable] {
        let retimed = WordRetiming.retimeDegenerate(ScriptMatcher.fixZeroLength(words), db: db, config: config)
        let syllables = alignWords(units: units, words: retimed, config: config)
        AlignmentRefinement.refineGroups(syllables, db: db, config: config)
        fillGaps(syllables, db: db, config: config)
        fillUnaligned(syllables)
        return syllables
    }

    static func alignWords(
        units: [ScriptUnit],
        words: [TimedWord],
        config: SpeechConfig = .default
    ) -> [TimedSyllable] {
        let match = ScriptMatcher.match(units: units, words: words, config: config)
        let recognized = match.recognized
        let positions = match.hangulPositions
        let syllables = units.map(TimedSyllable.init)

        for block in match.blocks {
            for offset in 0..<block.size {
                let syllable = syllables[positions[block.a + offset]]
                let heard = recognized[block.b + offset]
                syllable.startMs = heard.startMs
                syllable.endMs = heard.endMs
                syllable.aligned = true
                syllable.group = heard.wordIndex
                syllable.confidence = heard.prob
            }
        }

        for (previous, next) in match.gaps {
            let (aLow, aHigh) = (previous.a + previous.size, next.a)
            let (bLow, bHigh) = (previous.b + previous.size, next.b)
            if aHigh <= aLow || bHigh <= bLow { continue }
            let part = recognized[bLow..<bHigh]
            let span = TimeSpan(start: recognized[bLow].startMs, end: recognized[bHigh - 1].endMs)
            let meanProb = PyNumber.sum(part.map(\.prob)) / Double(part.count)
            let distance = Phonetic.soundDistance(
                positions[aLow..<aHigh].map { units[$0].char },
                part.map(\.char)
            )
            for position in positions[aLow..<aHigh] {
                syllables[position].hint = span
                syllables[position].mismatch = RecognitionMismatch(distance: distance, prob: meanProb)
            }
        }

        fillUnaligned(syllables)
        return syllables
    }

    static func fillUnaligned(_ syllables: [TimedSyllable]) {
        let count = syllables.count
        var index = 0
        while index < count {
            if syllables[index].timed {
                index += 1
                continue
            }
            var end = index
            while end < count && !syllables[end].timed { end += 1 }
            let left = index > 0 ? syllables[index - 1].endMs : nil
            let right = end < count ? syllables[end].startMs : nil
            let low = left ?? right ?? .zero
            let high = if let left, let right { PyNumber.max(left, right) } else { low }
            let step = (high - low) / Double(end - index)
            for position in index..<end {
                syllables[position].startMs = low + step * Double(position - index)
                syllables[position].endMs = low + step * Double(position - index + 1)
            }
            index = end
        }
    }

    static func voicedSegments(
        db: [Double],
        threshold: Double,
        from: Int,
        to: Int,
        config: SpeechConfig
    ) -> [Segment] {
        let low = max(0, from)
        let high = min(db.count, to)
        var segments: [Segment] = []
        var start: Int?
        if low < high {
            for frame in low..<high {
                if db[frame] > threshold {
                    if start == nil { start = frame }
                } else if let begun = start {
                    segments.append((begun, frame))
                    start = nil
                }
            }
        }
        if let start { segments.append((start, high)) }

        var merged: [Segment] = []
        let gap = config.frame(ms: Double(config.gapMergeMs))
        for segment in segments {
            if let last = merged.last, segment.start - last.end < gap {
                merged[merged.count - 1].end = segment.end
            } else {
                merged.append(segment)
            }
        }
        let minLength = config.frame(ms: Double(config.gapMinSegmentMs))
        return merged.filter { $0.end - $0.start >= minLength }
    }

    static func spread(_ run: [TimedSyllable], over segments: [Segment], config: SpeechConfig) {
        let weights = run.map { 1.0 + ($0.unit.hasBatchim ? config.batchimWeight : 0.0) }
        let lengths = segments.map { $0.end - $0.start }
        let totalVoiced = Double(lengths.reduce(0, +))
        let totalWeight = PyNumber.sum(weights)
        let cumulative = lengths.reduce(into: [0.0]) { $0.append($0[$0.count - 1] + Double($1)) }
        let hop = Double(config.hopMs)

        var accumulated = 0.0
        for (syllable, weight) in zip(run, weights) {
            let from = totalVoiced * accumulated / totalWeight
            let to = totalVoiced * (accumulated + weight) / totalWeight
            accumulated += weight
            let middle = (from + to) / 2
            let found = NumPy.searchSorted(cumulative, middle, right: true) - 1
            let index = min(max(found, 0), segments.count - 1)
            let frame = Double(segments[index].start) + (middle - cumulative[index])
            let half = (to - from) / 2
            let low = PyNumber(segments[index].start)
            let high = PyNumber(segments[index].end)
            let start = PyNumber(frame - half, isNumpy: true)
            let end = PyNumber(frame + half, isNumpy: true)
            syllable.startMs = PyNumber.max(low, PyNumber.min(high, start)) * hop
            syllable.endMs = PyNumber.max(low, PyNumber.min(high, end)) * hop
        }
    }

    static func fillGaps(_ syllables: [TimedSyllable], db: [Double], config: SpeechConfig) {
        guard !db.isEmpty else { return }
        let threshold = AcousticFeatures.speechThreshold(db)
        let durations = syllables.filter { $0.aligned && $0.durMs.value > 0 }.map(\.durMs.value)
        let typical = durations.isEmpty ? Double(config.defaultSyllableMs) : NumPy.median(durations)
        let totalMs = PyNumber(db.count * config.hopMs)
        let pad = Double(config.hintPadMs)
        let count = syllables.count
        var index = 0
        while index < count {
            if syllables[index].aligned {
                index += 1
                continue
            }
            var end = index
            while end < count && !syllables[end].aligned { end += 1 }
            let run = syllables[index..<end].filter(\.unit.isHangul)
            defer { index = end }
            guard !run.isEmpty else { continue }
            let low = index > 0 ? syllables[index - 1].endMs : .zero
            let high = end < count ? syllables[end].startMs : totalMs

            func segments(_ from: PyNumber, _ to: PyNumber) -> [Segment] {
                voicedSegments(
                    db: db,
                    threshold: threshold,
                    from: config.frame(ms: from.value),
                    to: config.frame(ms: to.value),
                    config: config
                )
            }

            if let hint = run.lazy.compactMap(\.hint).first {
                var from = PyNumber.max(low, hint.start - pad)
                var to = PyNumber.min(high, hint.end + pad)
                if to.value <= from.value { (from, to) = (hint.start, hint.end) }
                let voiced = segments(from, to)
                if voiced.isEmpty {
                    let step = (to - from) / Double(run.count)
                    for (offset, syllable) in run.enumerated() {
                        syllable.startMs = from + step * Double(offset)
                        syllable.endMs = from + step * Double(offset + 1)
                    }
                } else {
                    spread(run, over: voiced, config: config)
                }
                for syllable in run { syllable.inferred = true }
            } else {
                let voiced = segments(low, high)
                let voicedMs = Double(voiced.reduce(0) { $0 + $1.end - $1.start } * config.hopMs)
                if !voiced.isEmpty && voicedMs >= config.gapMinFillRatio * typical * Double(run.count) {
                    spread(run, over: voiced, config: config)
                    for syllable in run { syllable.inferred = true }
                }
            }
        }
    }
}
