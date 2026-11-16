//
//  PhraseBuilder.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated enum PhraseBuilder {
    static func build(_ syllables: [TimedSyllable], config: SpeechConfig) -> (phrases: [Phrase], baseline: Double) {
        let hangul = syllables.filter(\.unit.isHangul)

        var raw: [[TimedSyllable]] = []
        var current: [TimedSyllable] = []
        for (index, syllable) in hangul.enumerated() {
            current.append(syllable)
            let next = index + 1 < hangul.count ? hangul[index + 1] : nil
            let boundary = syllable.unit.boundaryAfter
            let hard = boundary == .comma || boundary == .line || boundary == .sentence || syllable.unit.isSentenceEnd
            let longPause = if let next {
                syllable.aligned && next.aligned
                    && next.startMs.value - syllable.endMs.value >= Double(config.phraseSplitPauseMs)
            } else {
                false
            }
            if next == nil || hard || longPause {
                raw.append(current)
                current = []
            }
        }

        var merged: [[TimedSyllable]] = []
        var carry: [TimedSyllable] = []
        for phrase in raw {
            let joined = carry + phrase
            carry = []
            if joined.count < config.minPhraseSyllables {
                carry = joined
            } else {
                merged.append(joined)
            }
        }
        if !carry.isEmpty {
            if merged.isEmpty {
                merged.append(carry)
            } else {
                merged[merged.count - 1] += carry
            }
        }

        var measured: [(phrase: [TimedSyllable], count: Int, seconds: PyNumber)] = []
        for phrase in merged {
            let aligned = phrase.filter(\.aligned)
            if aligned.count < 3 || Double(aligned.count) < config.phraseMinAlignedRatio * Double(phrase.count) {
                continue
            }
            var span = aligned[aligned.count - 1].endMs - aligned[0].startMs
            for (a, b) in zip(aligned, aligned.dropFirst()) {
                let gap = b.startMs - a.endMs
                if gap.value >= Double(config.pauseMinMs) { span = span - gap }
            }
            if span.value <= 0 { continue }
            let seconds = span / 1000
            guard config.plausibleRate.contains(Double(aligned.count) / seconds.value) else { continue }
            measured.append((phrase, aligned.count, seconds))
        }

        guard !measured.isEmpty else { return ([], 0) }

        let baseline = Double(measured.reduce(0) { $0 + $1.count }) / PyNumber.sum(measured.map(\.seconds))
        let phrases = measured.map { phrase, count, seconds in
            let rate = Double(count) / seconds
            let ratio = rate / baseline
            let label: SpeedLabel = if ratio.value >= config.fastRatio {
                .fast
            } else if ratio.value <= config.slowRatio {
                .slow
            } else {
                .normal
            }
            return Phrase(
                startIdx: phrase[0].unit.idx,
                endIdx: phrase[phrase.count - 1].unit.idx,
                speedSyllPerSec: rate.rounded(digits: 2),
                speedRatio: ratio.rounded(digits: 2),
                speedLabel: label
            )
        }
        return (phrases, baseline.value)
    }
}
