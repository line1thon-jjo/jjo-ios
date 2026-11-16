//
//  Disfluencies.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated enum Disfluencies {
    static let fillers: Set<String> = [
        "어", "음", "으", "아", "엄", "흠", "에", "으음", "어어", "음음", "아아", "그", "저", "뭐", "이제", "막", "그니까",
    ]
    private static let fillerSounds = Set("어음으아엄흠".unicodeScalars)

    static func isFillerSound(_ text: String) -> Bool {
        !text.isEmpty && text.unicodeScalars.allSatisfy(fillerSounds.contains)
    }

    static func findInsertions(units: [ScriptUnit], words: [TimedWord], config: SpeechConfig) -> [Disfluency] {
        guard !words.isEmpty else { return [] }
        let match = ScriptMatcher.match(units: units, words: words, config: config)
        let chars = match.hangulPositions.map { units[$0].char }

        var out: [Disfluency] = []
        for (previous, next) in zip(match.blocks, match.blocks.dropFirst()) {
            if next.a != previous.a + previous.size { continue }
            let extra = match.recognized[(previous.b + previous.size)..<next.b]
            guard let first = extra.first, let last = extra.last else { continue }
            let heard = extra.map(\.char)
            let text = heard.text
            let before = Array(chars[max(0, next.a - heard.count)..<next.a])
            let after = Array(chars[next.a..<min(chars.count, next.a + heard.count)])
            let type: DisfluencyType = if fillers.contains(text) || isFillerSound(text) {
                .filler
            } else if before == heard || after == heard {
                .repeat
            } else {
                .insertion
            }
            out.append(
                Disfluency(
                    type: type,
                    beforeIdx: units[match.hangulPositions[next.a]].idx,
                    startMs: PyNumber.round(first.startMs.value),
                    endMs: PyNumber.round(last.endMs.value),
                    text: text
                )
            )
        }
        return out
    }

    static func findStraySounds(
        _ syllables: [TimedSyllable],
        db: [Double],
        f0: [Double],
        config: SpeechConfig
    ) -> [Disfluency] {
        guard !db.isEmpty else { return [] }
        let peak = NumPy.percentile(db, 95)
        let threshold = peak - config.strayBelowPeakDb
        let voiced = db.indices.map { db[$0] > threshold && $0 < f0.count && !f0[$0].isNaN }

        let minLength = config.frame(ms: Double(config.strayMinMs))
        let margin = config.frame(ms: Double(config.strayMarginMs))
        let join = config.frame(ms: Double(config.gapMergeMs))

        let hangul = syllables.filter(\.unit.isHangul)
        var out: [Disfluency] = []
        for (a, b) in zip(hangul, hangul.dropFirst()) {
            guard a.aligned, b.aligned, !a.inferred, !b.inferred else { continue }
            if b.startMs.value - a.endMs.value < Double(config.pauseMinMs) { continue }
            // 앞 어절의 인식 확신이 낮으면 끝 시각이 부정확해, 바로 뒤의 소리는 그 어절의 끝소리일 수 있다.
            if let confidence = a.confidence, confidence < config.lowProb { continue }
            if let group = a.group, group == b.group { continue }
            let low = config.frame(ms: a.endMs.value) + margin
            let high = config.frame(ms: b.startMs.value) - margin
            if low < 0 || high - low < minLength { continue }
            let span = high - low
            let energetic = low < db.count ? db[low..<min(high, db.count)].map { $0 > threshold } : []

            var merged: [Alignment.Segment] = []
            var start: Int?
            for index in 0...energetic.count {
                let isOn = index < energetic.count && energetic[index]
                if isOn && start == nil {
                    start = index
                } else if !isOn, let begun = start {
                    if let last = merged.last, begun - last.end < join {
                        merged[merged.count - 1].end = index
                    } else {
                        merged.append((begun, index))
                    }
                    start = nil
                }
            }

            for (start, end) in merged {
                if end - start < minLength { continue }
                // 앞 음절 끝이나 뒤 음절 시작에 붙어 있으면 그 음절 자체의 꼬리/첫소리다.
                if start == 0 || end == span { continue }
                let range = (low + start)..<(low + end)
                let loud = NumPy.mean(db[range]) >= peak - config.strayLoudBelowPeakDb
                let voicedRatio = Double(voiced[range].count(where: { $0 })) / Double(range.count)
                // 목소리도 아니고 크지도 않으면(숨소리·잡음) 세지 않는다. 기침처럼 큰 소리는 센다.
                if voicedRatio < config.strayVoicedRatio && !loud { continue }
                out.append(
                    Disfluency(
                        type: .straySound,
                        beforeIdx: b.unit.idx,
                        startMs: (low + start) * config.hopMs,
                        endMs: (low + end) * config.hopMs
                    )
                )
            }
        }
        return out
    }

    static func merge(byWords: [Disfluency], bySound: [Disfluency]) -> [Disfluency] {
        let kept = bySound.filter { sound in
            !byWords.contains { sound.startMs < $0.endMs && $0.startMs < sound.endMs }
        }
        return (byWords + kept).enumerated()
            .sorted { ($0.element.startMs, $0.offset) < ($1.element.startMs, $1.offset) }
            .map(\.element)
    }

    static func pausesWithDisfluency(_ syllables: [TimedSyllable], found: [Disfluency]) -> Set<Int> {
        var skip: Set<Int> = []
        let hangul = syllables.filter(\.unit.isHangul)
        for (a, b) in zip(hangul, hangul.dropFirst()) where a.aligned && b.aligned {
            let (gapStart, gapEnd) = (a.endMs.value, b.startMs.value)
            if found.contains(where: { Double($0.startMs) < gapEnd && Double($0.endMs) > gapStart }) {
                skip.insert(a.unit.idx)
            }
        }
        return skip
    }
}
