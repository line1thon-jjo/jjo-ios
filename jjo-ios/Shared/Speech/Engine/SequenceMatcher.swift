//
//  SequenceMatcher.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated struct SequenceMatch: Equatable, Sendable {
    let a: Int
    let b: Int
    let size: Int
}

// difflib.SequenceMatcher(autojunk=False) 와 같은 순서로 가장 긴 공통 구간을 고른다. 동률일 때의 선택까지 같아야 글자 idx 가 맞는다.
nonisolated struct SequenceMatcher<Element: Hashable> {
    private let a: [Element]
    private let b: [Element]
    private let positions: [Element: [Int]]

    init(a: [Element], b: [Element]) {
        self.a = a
        self.b = b
        var positions: [Element: [Int]] = [:]
        for (index, element) in b.enumerated() {
            positions[element, default: []].append(index)
        }
        self.positions = positions
    }

    func matchingBlocks() -> [SequenceMatch] {
        var lengths = [Int](repeating: 0, count: b.count + 1)
        var nextLengths = lengths
        var queue = [(0, a.count, 0, b.count)]
        var found: [SequenceMatch] = []
        while let (aLow, aHigh, bLow, bHigh) = queue.popLast() {
            let match = longestMatch(aLow, aHigh, bLow, bHigh, &lengths, &nextLengths)
            guard match.size > 0 else { continue }
            found.append(match)
            if aLow < match.a && bLow < match.b {
                queue.append((aLow, match.a, bLow, match.b))
            }
            if match.a + match.size < aHigh && match.b + match.size < bHigh {
                queue.append((match.a + match.size, aHigh, match.b + match.size, bHigh))
            }
        }
        found.sort { ($0.a, $0.b, $0.size) < ($1.a, $1.b, $1.size) }

        var blocks: [SequenceMatch] = []
        var (startA, startB, size) = (0, 0, 0)
        for match in found {
            if startA + size == match.a && startB + size == match.b {
                size += match.size
            } else {
                if size > 0 { blocks.append(SequenceMatch(a: startA, b: startB, size: size)) }
                (startA, startB, size) = (match.a, match.b, match.size)
            }
        }
        if size > 0 { blocks.append(SequenceMatch(a: startA, b: startB, size: size)) }
        blocks.append(SequenceMatch(a: a.count, b: b.count, size: 0))
        return blocks
    }

    private func longestMatch(
        _ aLow: Int,
        _ aHigh: Int,
        _ bLow: Int,
        _ bHigh: Int,
        _ lengths: inout [Int],
        _ nextLengths: inout [Int]
    ) -> SequenceMatch {
        var (bestA, bestB, bestSize) = (aLow, bLow, 0)
        var touched: [Int] = []
        var nextTouched: [Int] = []
        for i in aLow..<aHigh {
            nextTouched.removeAll(keepingCapacity: true)
            if let candidates = positions[a[i]] {
                for j in candidates[firstIndex(in: candidates, atLeast: bLow)...] {
                    if j >= bHigh { break }
                    let length = lengths[j] + 1
                    nextLengths[j + 1] = length
                    nextTouched.append(j + 1)
                    if length > bestSize {
                        (bestA, bestB, bestSize) = (i - length + 1, j - length + 1, length)
                    }
                }
            }
            for index in touched { lengths[index] = 0 }
            swap(&lengths, &nextLengths)
            swap(&touched, &nextTouched)
        }
        for index in touched { lengths[index] = 0 }

        while bestA > aLow && bestB > bLow && a[bestA - 1] == b[bestB - 1] {
            (bestA, bestB, bestSize) = (bestA - 1, bestB - 1, bestSize + 1)
        }
        while bestA + bestSize < aHigh && bestB + bestSize < bHigh && a[bestA + bestSize] == b[bestB + bestSize] {
            bestSize += 1
        }
        return SequenceMatch(a: bestA, b: bestB, size: bestSize)
    }

    private func firstIndex(in candidates: [Int], atLeast bound: Int) -> Int {
        var low = 0
        var high = candidates.count
        while low < high {
            let middle = (low + high) / 2
            if candidates[middle] < bound {
                low = middle + 1
            } else {
                high = middle
            }
        }
        return low
    }
}
