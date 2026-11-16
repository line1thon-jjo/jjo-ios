//
//  Numerals.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

// 인식기는 숫자를 아라비아 숫자로 적는다. 대본에 실제로 있는 읽기(한자어·고유어)를 골라 한글로 바꿔야 비교할 수 있다.
nonisolated enum Numerals {
    private static let sinoDigits = ["영", "일", "이", "삼", "사", "오", "육", "칠", "팔", "구"]
    private static let nativeUnit = ["", "하나", "둘", "셋", "넷", "다섯", "여섯", "일곱", "여덟", "아홉"]
    private static let nativeUnitDet = ["", "한", "두", "세", "네", "다섯", "여섯", "일곱", "여덟", "아홉"]
    private static let nativeTens = ["", "열", "스물", "서른", "마흔", "쉰", "예순", "일흔", "여든", "아흔"]
    private static let nativeTensDet = ["", "열", "스무", "서른", "마흔", "쉰", "예순", "일흔", "여든", "아흔"]
    private static let big = ["", "만", "억", "조"]
    private static let sinoLimit = 10_000_000_000_000_000

    static func sino(_ number: Int) -> String {
        guard number != 0 else { return sinoDigits[0] }
        var groups: [Int] = []
        var rest = number
        while rest != 0 {
            groups.append(rest % 10000)
            rest /= 10000
        }
        var parts = ""
        for groupIndex in groups.indices.reversed() {
            let group = groups[groupIndex]
            if group == 0 { continue }
            var text = ""
            for (divisor, unit) in [(1000, "천"), (100, "백"), (10, "십"), (1, "")] {
                let digit = (group / divisor) % 10
                if digit == 0 { continue }
                text += (digit == 1 && !unit.isEmpty ? "" : sinoDigits[digit]) + unit
            }
            if groupIndex == 1 && group == 1 { text = "" }
            parts += text + big[groupIndex]
        }
        return parts
    }

    static func nativeForms(_ number: Int) -> [String] {
        guard (1...99).contains(number) else { return [] }
        let (tens, unit) = number.quotientAndRemainder(dividingBy: 10)
        if unit == 0 { return [nativeTensDet[tens]] }
        let forms = Set([nativeTens[tens] + nativeUnit[unit], nativeTens[tens] + nativeUnitDet[unit]])
        return forms.sorted { $0.unicodeScalars.lexicographicallyPrecedes($1.unicodeScalars) }
    }

    static func normalize(_ words: [WordTiming], script: String) -> [WordTiming] {
        let scriptHangul = Array(script.unicodeScalars.filter(\.isHangulSyllable))
        return words.map { word in
            let scalars = Array(word.text.unicodeScalars)
            guard scalars.contains(where: \.isPythonDigit) else { return word }
            let options = pieces(scalars).map { piece -> [[Unicode.Scalar]] in
                guard piece[0].isPythonDigit else { return [piece.filter(\.isHangulSyllable)] }
                let found = candidates(piece)
                return found.isEmpty ? [piece] : found.map { Array($0.unicodeScalars) }
            }
            guard let chosen = firstReading(options, in: scriptHangul) else { return word }
            var replaced = word
            replaced.text = chosen.text
            return replaced
        }
    }

    private static func pieces(_ scalars: [Unicode.Scalar]) -> [[Unicode.Scalar]] {
        var result: [[Unicode.Scalar]] = []
        var index = 0
        while index < scalars.count {
            var end = index + 1
            if scalars[index].isPythonDecimal {
                while end < scalars.count && (scalars[end].isPythonDecimal || scalars[end] == ",") { end += 1 }
                if end + 1 < scalars.count && scalars[end] == "." && scalars[end + 1].isPythonDecimal {
                    end += 2
                    while end < scalars.count && scalars[end].isPythonDecimal { end += 1 }
                }
            } else {
                while end < scalars.count && !scalars[end].isPythonDecimal { end += 1 }
            }
            result.append(Array(scalars[index..<end]))
            index = end
        }
        return result
    }

    private static func candidates(_ piece: [Unicode.Scalar]) -> [String] {
        guard !piece.contains("."), let number = integer(piece) else { return [] }
        var result = [sino(number)] + nativeForms(number)
        if number == 6 { result.append("유") }
        if number == 10 { result.append("시") }
        return result
    }

    private static func integer(_ piece: [Unicode.Scalar]) -> Int? {
        var number = 0
        var hasDigit = false
        for scalar in piece where scalar != "," {
            guard scalar.isPythonDecimal, let digit = scalar.properties.numericValue else { return nil }
            number = number * 10 + Int(digit)
            hasDigit = true
            if number >= sinoLimit { return nil }
        }
        return hasDigit ? number : nil
    }

    private static func firstReading(
        _ options: [[[Unicode.Scalar]]],
        in script: [Unicode.Scalar]
    ) -> [Unicode.Scalar]? {
        var picks = [Int](repeating: 0, count: options.count)
        while true {
            let candidate = zip(options, picks).flatMap { $0[$1] }
            if !candidate.isEmpty && !candidate.contains(where: \.isPythonDigit) && contains(script, candidate) {
                return candidate
            }
            var position = options.count - 1
            while position >= 0 {
                picks[position] += 1
                if picks[position] < options[position].count { break }
                picks[position] = 0
                position -= 1
            }
            if position < 0 { return nil }
        }
    }

    private static func contains(_ text: [Unicode.Scalar], _ part: [Unicode.Scalar]) -> Bool {
        guard part.count <= text.count else { return false }
        return (0...(text.count - part.count)).contains { text[$0..<($0 + part.count)].elementsEqual(part) }
    }
}
