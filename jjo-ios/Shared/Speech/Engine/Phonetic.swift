//
//  Phonetic.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated enum Phonetic {
    private struct Jamo {
        let cho: Int
        let jung: Int
        let jong: Int

        init?(_ scalar: Unicode.Scalar) {
            guard scalar.isHangulSyllable else { return nil }
            let code = Int(scalar.value) - 0xAC00
            cho = code / 588
            jung = (code % 588) / 28
            jong = code % 28
        }
    }

    private static let vowelMerge = [3: 1, 5: 1, 7: 1]
    // 준말(되어→돼, 보아→봐, 하여→해, 주는→준, 것인→건)은 같은 소리로 본다.
    private static let vowelJoin: [Int: Int] = [
        key(8, 0): 9, key(13, 4): 14, key(11, 4): 10, key(20, 4): 6, key(0, 6): 1, key(18, 4): 4,
        key(1, 4): 1, key(0, 0): 0, key(0, 4): 0, key(4, 4): 4, key(5, 4): 5, key(20, 6): 6, key(8, 4): 4,
    ]
    private static let openVowels: Set<Int> = [0, 4, 6]
    private static let geotContractions: [Unicode.Scalar: Unicode.Scalar] = ["이": "게", "은": "건", "을": "걸", "인": "건"]

    static func soundDistance(_ lhs: [Unicode.Scalar], _ rhs: [Unicode.Scalar]) -> Double {
        let first = tokens(contract(lhs))
        let second = tokens(contract(rhs))
        if first.isEmpty && second.isEmpty { return 0 }
        var previous = Array(0...second.count)
        var current = [Int](repeating: 0, count: second.count + 1)
        for (row, token) in first.enumerated() {
            current[0] = row + 1
            for (column, other) in second.enumerated() {
                let substitution = previous[column] + (token != other ? 1 : 0)
                current[column + 1] = min(previous[column + 1] + 1, current[column] + 1, substitution)
            }
            swap(&previous, &current)
        }
        return Double(previous[second.count]) / Double(max(first.count, second.count))
    }

    static func soundDistance(_ lhs: String, _ rhs: String) -> Double {
        soundDistance(Array(lhs.unicodeScalars), Array(rhs.unicodeScalars))
    }

    private static func key(_ previous: Int, _ current: Int) -> Int {
        previous * 100 + current
    }

    private static func join(_ cho: Int, _ jung: Int, _ jong: Int) -> Unicode.Scalar {
        Unicode.Scalar(UInt32(0xAC00 + cho * 588 + jung * 28 + jong)) ?? "가"
    }

    private static func contract(_ text: [Unicode.Scalar]) -> [Unicode.Scalar] {
        var out: [Unicode.Scalar] = []
        for char in text {
            guard let current = Jamo(char), let last = out.last, let previous = Jamo(last) else {
                out.append(char)
                continue
            }
            if last == "것", let contracted = geotContractions[char] {
                out[out.count - 1] = contracted
                continue
            }
            if previous.jong == 0 && current.cho == 11 && openVowels.contains(current.jung),
               let joined = vowelJoin[key(previous.jung, current.jung)] {
                out[out.count - 1] = join(previous.cho, joined, current.jong)
                continue
            }
            if previous.jong == 0 && (char == "는" || char == "를") {
                out[out.count - 1] = join(previous.cho, previous.jung, char == "는" ? 4 : 8)
                continue
            }
            out.append(char)
        }
        return out
    }

    private static func tokens(_ text: [Unicode.Scalar]) -> [Int] {
        var out: [Int] = []
        for char in text {
            guard let jamo = Jamo(char) else { continue }
            out.append(jamo.cho)
            out.append(100 + (vowelMerge[jamo.jung] ?? jamo.jung))
            if jamo.jong != 0 { out.append(200 + jamo.jong) }
        }
        return out
    }
}
