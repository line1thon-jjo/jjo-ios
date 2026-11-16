//
//  ScriptText.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated enum ScriptText {
    private struct RawUnit {
        let idx: Int
        let char: Unicode.Scalar
        let wordId: Int
        var boundary = ScriptBoundary.none
        var isQuestion = false
    }

    private static let sentenceEndChars = Set(".?!…。？！".unicodeScalars)
    private static let questionChars = Set("?？".unicodeScalars)
    private static let commaChars = Set(",;:、，；：".unicodeScalars)
    private static let nounYo: Set<String> = ["필요", "불필요", "중요", "주요", "수요", "개요", "요"]
    private static let nounDa: Set<String> = ["다", "바다"]
    private static let yoStems = Set("어아해에예세네군래데까나지게워여가".unicodeScalars)
    private static let clauseEndings = [
        "는데", "지만", "니까", "으며", "면서", "어서", "아서", "해서", "라서", "인데",
        "다면", "으니", "으면", "라면", "거나", "든지", "더니", "다가",
        "하고", "이고", "되고", "있고", "없고", "했고", "였고", "겠고",
    ]
    private static let jongB: UInt32 = 17

    static func parse(_ script: String) -> [ScriptUnit] {
        let scalars = Array(script.unicodeScalars)
        var raw: [RawUnit] = []
        var wordId = 0
        var inWord = false

        func upgrade(_ boundary: ScriptBoundary) {
            guard let last = raw.indices.last, boundary.rawValue > raw[last].boundary.rawValue else { return }
            raw[last].boundary = boundary
        }

        for (idx, char) in scalars.enumerated() {
            if char.isPythonSpace {
                if inWord {
                    wordId += 1
                    inWord = false
                }
                upgrade(char == "\r" || char == "\n" ? .line : .word)
            } else if sentenceEndChars.contains(char) {
                let isDecimalPoint = char == "." && idx > 0 && idx < scalars.count - 1
                    && scalars[idx - 1].isPythonDigit && scalars[idx + 1].isPythonDigit
                if isDecimalPoint { continue }
                upgrade(.sentence)
                if let last = raw.indices.last, questionChars.contains(char) {
                    raw[last].isQuestion = true
                }
            } else if commaChars.contains(char) {
                upgrade(.comma)
            } else if char.isPunctuationSymbolOrControl {
                continue
            } else {
                raw.append(RawUnit(idx: idx, char: char, wordId: wordId))
                inWord = true
            }
        }

        guard !raw.isEmpty else { return [] }

        let hasSentencePunctuation = raw.contains { $0.boundary == .sentence }
        inferBoundaries(&raw, allowSentence: !hasSentencePunctuation)

        var units: [ScriptUnit] = []
        units.reserveCapacity(raw.count)
        var sentenceId = 0
        for (position, unit) in raw.enumerated() {
            let endsSentence = hasSentencePunctuation
                ? unit.boundary == .sentence
                : unit.boundary == .line || unit.boundary == .sentence
            let isEnd = endsSentence || position == raw.count - 1
            units.append(
                ScriptUnit(
                    idx: unit.idx,
                    char: unit.char,
                    isHangul: unit.char.isHangulSyllable,
                    wordId: unit.wordId,
                    boundaryAfter: unit.boundary,
                    strength: isEnd ? 3 : unit.boundary.strength,
                    sentenceId: sentenceId,
                    isSentenceEnd: isEnd,
                    isQuestionEnd: isEnd && unit.isQuestion
                )
            )
            if isEnd { sentenceId += 1 }
        }
        return units
    }

    static func isSentenceFinal(_ word: [Unicode.Scalar]) -> Bool {
        let text = word.text
        if nounYo.contains(text) || nounDa.contains(text) { return false }
        if isQuestionWord(word) { return true }
        if word.hasSuffix("다") { return word.count >= 2 }
        if word.hasSuffix("요") { return word.count >= 2 && yoStems.contains(word[word.count - 2]) }
        return word.count >= 2 && word.hasSuffix("죠")
    }

    private static func isQuestionWord(_ word: [Unicode.Scalar]) -> Bool {
        if word.hasSuffix("니까") {
            guard word.count >= 3 else { return false }
            let stem = word[word.count - 3]
            return stem.isHangulSyllable && (stem.value - 0xAC00) % 28 == jongB
        }
        if word.hasSuffix("까요") || word.hasSuffix("나요") { return true }
        return word.count >= 2 && word.hasSuffix("까")
    }

    private static func isClauseEnd(_ word: [Unicode.Scalar]) -> Bool {
        clauseEndings.contains { word.hasSuffix($0) }
    }

    private static func inferBoundaries(_ raw: inout [RawUnit], allowSentence: Bool) {
        var words: [Int: [Unicode.Scalar]] = [:]
        var lasts: [Int: Int] = [:]
        for (position, unit) in raw.enumerated() {
            words[unit.wordId, default: []].append(unit.char)
            lasts[unit.wordId] = position
        }
        for (wordId, position) in lasts {
            guard raw[position].boundary == .word || raw[position].boundary == .none else { continue }
            let word = (words[wordId] ?? []).filter(\.isHangulSyllable)
            guard !word.isEmpty else { continue }
            if allowSentence && isSentenceFinal(word) {
                raw[position].boundary = .sentence
                raw[position].isQuestion = isQuestionWord(word)
            } else if raw[position].boundary == .word && isClauseEnd(word) {
                raw[position].boundary = .comma
            }
        }
    }
}
