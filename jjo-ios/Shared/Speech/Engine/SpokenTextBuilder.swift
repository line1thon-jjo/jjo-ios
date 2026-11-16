//
//  SpokenTextBuilder.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated struct SpokenText: Equatable, Sendable {
    var text: String
    var differences: [SpokenDifference]
    var matchRatio: Double
}

// 대본과 확실히 다르게 말한 부분만 말한 단어로 바꾼다.
// 발음이 비슷한 차이·군말·반복·확신이 낮은 인식은 대본 그대로 둔다.
nonisolated enum SpokenTextBuilder {
    private typealias Scalars = [Unicode.Scalar]

    private struct Replacement {
        let lastIdx: Int
        let spoken: Scalars
    }

    private struct Difference {
        var kind: SpokenKind
        var startIdx: Int
        var endIdx: Int
        var spoken: Scalars
        var scriptText: Scalars?
    }

    private static let space: Unicode.Scalar = " "

    static func build(
        script: String,
        units: [ScriptUnit],
        words: [TimedWord],
        config: SpeechConfig
    ) -> SpokenText {
        let hangulTotal = units.count(where: \.isHangul)
        guard !words.isEmpty, hangulTotal > 0 else {
            return SpokenText(text: script, differences: [], matchRatio: 0)
        }

        let match = ScriptMatcher.match(units: units, words: words, config: config)
        let recognized = match.recognized
        let positions = match.hangulPositions
        let chars = positions.map { units[$0].char }
        let ratio = Double(match.blocks.reduce(0) { $0 + $1.size }) / Double(hangulTotal)
        let scalars = Array(script.unicodeScalars)

        var replaceAt: [Int: Replacement] = [:]
        var insertAt: [Int: [Scalars]] = [:]

        func idx(_ position: Int) -> Int {
            units[positions[position]].idx
        }

        for (previous, next) in match.gaps {
            let (aLow, aHigh) = (previous.a + previous.size, next.a)
            let (bLow, bHigh) = (previous.b + previous.size, next.b)
            if bHigh <= bLow { continue }
            let part = Array(recognized[bLow..<bHigh])
            let probs = part.map(\.prob)
            let meanProb = PyNumber.sum(probs) / Double(probs.count)
            // 짧은 차이는 확신이 높아야 채택한다. 길게 다른 말로 인식되면 우연한 오인식일 가능성이 낮아 기준을 조금 낮춘다.
            let isLong = part.count >= config.deviationLongSyllables
            let strong = part.count >= config.deviationMinSyllables && meanProb >= config.deviationMinProb
            let longEnough = isLong && meanProb >= config.deviationLongProb
            let minWordProb = isLong ? config.deviationLongMinWordProb : config.deviationMinWordProb
            if !(strong || longEnough) || (probs.min() ?? 0) < minWordProb { continue }

            let scriptPart = Array(chars[aLow..<aHigh])
            if aHigh > aLow
                && Phonetic.soundDistance(scriptPart, part.map(\.char)) <= config.substituteMinDistance {
                continue
            }

            var headCount = 0
            if bLow > 0 && aLow > 0 {
                while headCount < part.count && part[headCount].wordIndex == recognized[bLow - 1].wordIndex {
                    headCount += 1
                }
            }
            var tailCount = 0
            if bHigh < recognized.count && aHigh < chars.count {
                while tailCount < part.count - headCount
                    && part[part.count - 1 - tailCount].wordIndex == recognized[bHigh].wordIndex {
                    tailCount += 1
                }
            }
            var head = Array(part[..<headCount])
            var middle = Array(part[headCount..<(part.count - tailCount)])
            var tail = Array(part[(part.count - tailCount)...])

            if aHigh > aLow && middle.isEmpty {
                if !isLong { continue }
                // 두 어절에 걸쳐 길게 다른 말을 한 경우에는 어절 경계로 나누지 않고 전체를 말한 내용으로 바꾼다.
                (head, middle, tail) = ([], part, [])
            }
            if !head.isEmpty {
                insertAt[idx(aLow - 1) + 1, default: []].append(text(of: head))
            }

            let spoken = text(of: middle)
            let compact = spoken.filter { $0 != space }
            var keepMiddle = middle.isEmpty || Disfluencies.fillers.contains(compact.text)
            if !keepMiddle && aHigh > aLow {
                if Phonetic.soundDistance(scriptPart, compact) <= config.substituteMinDistance {
                    keepMiddle = true
                } else {
                    let firstIdx = idx(aLow)
                    let gluedHead = !head.isEmpty && firstIdx == idx(aLow - 1) + 1
                    let replaced = (gluedHead ? [space] : []) + spoken + (tail.isEmpty ? [] : [space])
                    replaceAt[firstIdx] = Replacement(lastIdx: idx(aHigh - 1), spoken: replaced)
                }
            } else if !keepMiddle {
                let before = Array(chars[max(0, aLow - compact.count)..<aLow])
                let after = Array(chars[aLow..<min(chars.count, aLow + compact.count)])
                if before == compact || after == compact {
                    keepMiddle = true
                } else {
                    let position = aLow < positions.count ? idx(aLow) : scalars.count
                    let lastWord = Array(spoken.split(separator: space, omittingEmptySubsequences: false).last ?? [])
                    let separator = Array((ScriptText.isSentenceFinal(lastWord) ? ". " : " ").unicodeScalars)
                    insertAt[position, default: []].append(spoken + separator)
                }
            }

            if !tail.isEmpty {
                insertAt[idx(aHigh), default: []].append(text(of: tail))
            }
        }

        if replaceAt.isEmpty && insertAt.isEmpty {
            return SpokenText(text: script, differences: [], matchRatio: ratio)
        }

        var out: Scalars = []
        var differences: [Difference] = []
        var index = 0
        while index <= scalars.count {
            for piece in insertAt[index] ?? [] {
                let trimmed = piece.count - piece.reversed().prefix { $0 == "." || $0 == space }.count
                differences.append(
                    Difference(
                        kind: .added,
                        startIdx: out.count,
                        endIdx: out.count + trimmed - 1,
                        spoken: Array(piece[..<trimmed])
                    )
                )
                out += piece
            }
            if index == scalars.count { break }
            if let replacement = replaceAt[index] {
                let spoken = replacement.spoken
                let lead = spoken.prefix(while: \.isPythonSpace).count
                let trail = lead < spoken.count ? spoken.reversed().prefix(while: \.isPythonSpace).count : 0
                let core = Array(spoken[lead..<(spoken.count - trail)])
                differences.append(
                    Difference(
                        kind: .replaced,
                        startIdx: out.count + lead,
                        endIdx: out.count + lead + core.count - 1,
                        spoken: core,
                        scriptText: Array(scalars[index...replacement.lastIdx])
                    )
                )
                out += spoken
                index = replacement.lastIdx + 1
                continue
            }
            out.append(scalars[index])
            index += 1
        }
        while let last = out.last, last.isPythonSpace { out.removeLast() }

        let merged = mergeAdjacent(out, differences).map {
            SpokenDifference(
                kind: $0.kind,
                startIdx: $0.startIdx,
                endIdx: $0.endIdx,
                spoken: $0.spoken.text,
                scriptText: $0.scriptText?.text
            )
        }
        return SpokenText(text: out.text, differences: merged, matchRatio: ratio)
    }

    private static func text(of part: [RecognizedSyllable]) -> Scalars {
        var pieces: Scalars = []
        var lastWord: Int?
        for syllable in part {
            if let lastWord, syllable.wordIndex != lastWord { pieces.append(space) }
            pieces.append(syllable.char)
            lastWord = syllable.wordIndex
        }
        return pieces
    }

    private static func mergeAdjacent(_ text: Scalars, _ differences: [Difference]) -> [Difference] {
        let sorted = differences.enumerated()
            .sorted { ($0.element.startIdx, $0.offset) < ($1.element.startIdx, $1.offset) }
            .map(\.element)
        var merged: [Difference] = []
        for difference in sorted {
            guard let last = merged.last, difference.startIdx - last.endIdx <= 2 else {
                merged.append(difference)
                continue
            }
            let scripts = [last.scriptText, difference.scriptText].compactMap { $0 }.filter { !$0.isEmpty }
            let low = min(max(last.startIdx, 0), text.count)
            let high = min(max(difference.endIdx + 1, low), text.count)
            merged[merged.count - 1] = Difference(
                kind: scripts.isEmpty ? .added : .replaced,
                startIdx: last.startIdx,
                endIdx: difference.endIdx,
                spoken: Array(text[low..<high]),
                scriptText: scripts.isEmpty ? nil : Array(scripts.joined(separator: [space]))
            )
        }
        return merged
    }
}
