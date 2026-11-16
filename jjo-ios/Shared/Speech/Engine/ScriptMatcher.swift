//
//  ScriptMatcher.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated struct RecognizedSyllable: Equatable, Sendable {
    let char: Unicode.Scalar
    let startMs: PyNumber
    let endMs: PyNumber
    let wordIndex: Int
    let prob: Double
}

nonisolated struct ScriptMatch: Sendable {
    let recognized: [RecognizedSyllable]
    let hangulPositions: [Int]
    let blocks: [SequenceMatch]

    var gaps: [(previous: SequenceMatch, next: SequenceMatch)] {
        let edges = [SequenceMatch(a: 0, b: 0, size: 0)] + blocks
            + [SequenceMatch(a: hangulPositions.count, b: recognized.count, size: 0)]
        return zip(edges, edges.dropFirst()).map { (previous: $0, next: $1) }
    }
}

nonisolated enum ScriptMatcher {
    static let zeroLengthCharSeconds = 0.08

    static func match(units: [ScriptUnit], words: [TimedWord], config: SpeechConfig = .default) -> ScriptMatch {
        var recognized: [RecognizedSyllable] = []
        for (wordIndex, word) in fixZeroLength(words).enumerated() {
            let chars = word.hangul
            if chars.isEmpty || word.end.value <= word.start.value { continue }
            let step = (word.end - word.start) * 1000 / Double(chars.count)
            for (offset, char) in chars.enumerated() {
                recognized.append(
                    RecognizedSyllable(
                        char: char,
                        startMs: word.start * 1000 + step * Double(offset),
                        endMs: word.start * 1000 + step * Double(offset + 1),
                        wordIndex: wordIndex,
                        prob: word.prob
                    )
                )
            }
        }

        let hangulPositions = units.indices.filter { units[$0].isHangul }
        let matcher = SequenceMatcher(a: hangulPositions.map { units[$0].char }, b: recognized.map(\.char))
        let blocks = matcher.matchingBlocks().filter { $0.size >= config.anchorMinChars }
        return ScriptMatch(recognized: recognized, hangulPositions: hangulPositions, blocks: blocks)
    }

    // 시작=끝 으로 온 단어를 버리면 말한 글자가 '건너뜀'으로 잡힌다. 짧은 길이를 임시로 주고 이후 단계에서 다시 맞춘다.
    static func fixZeroLength(_ words: [TimedWord]) -> [TimedWord] {
        var out: [TimedWord] = []
        out.reserveCapacity(words.count)
        for (index, word) in words.enumerated() {
            let count = word.hangulCount
            if count == 0 || word.end.value > word.start.value {
                out.append(word)
                continue
            }
            var end = word.start + zeroLengthCharSeconds * Double(count)
            if let next = words[(index + 1)...].first(where: { $0.start.value > word.start.value }) {
                end = PyNumber.min(end, next.start)
            }
            var fixed = word
            fixed.end = end
            out.append(fixed)
        }
        return out
    }
}
