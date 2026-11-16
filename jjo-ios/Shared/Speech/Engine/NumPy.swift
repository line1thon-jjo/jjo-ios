//
//  NumPy.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated enum NumPy {
    static func percentile(_ values: [Double], _ q: Double) -> Double {
        percentile(sorted: values.sorted(), q)
    }

    static func percentile(sorted: [Double], _ q: Double) -> Double {
        guard let last = sorted.last else { return .nan }
        let virtual = Double(sorted.count - 1) * (q / 100)
        guard virtual < Double(sorted.count - 1) else { return last }
        guard virtual >= 0 else { return sorted[0] }
        let previous = virtual.rounded(.down)
        let gamma = virtual - previous
        let lower = sorted[Int(previous)]
        let upper = sorted[Int(previous) + 1]
        let difference = upper - lower
        return gamma >= 0.5 ? upper - difference * (1 - gamma) : lower + difference * gamma
    }

    static func median(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return .nan }
        let sorted = values.sorted()
        let middle = sorted.count / 2
        return sorted.count % 2 == 1 ? sorted[middle] : (sorted[middle - 1] + sorted[middle]) / 2
    }

    static func round(_ value: Double, digits: Int) -> Double {
        let scale = pow(10.0, Double(digits))
        return (value * scale).rounded(.toNearestOrEven) / scale
    }

    static func searchSorted(_ sorted: [Double], _ value: Double, right: Bool) -> Int {
        var low = 0
        var high = sorted.count
        while low < high {
            let middle = (low + high) / 2
            if right ? sorted[middle] <= value : sorted[middle] < value {
                low = middle + 1
            } else {
                high = middle
            }
        }
        return low
    }

    // numpy 의 합은 8갈래 누적과 반씩 나누기를 섞어 쓴다. 같은 순서로 더해야 마지막 자리까지 같은 값이 나온다.
    static func pairwiseSum(_ values: UnsafeBufferPointer<Double>) -> Double {
        let count = values.count
        if count < 8 {
            var result = 0.0
            for value in values { result += value }
            return result
        }
        if count <= 128 {
            var r0 = values[0], r1 = values[1], r2 = values[2], r3 = values[3]
            var r4 = values[4], r5 = values[5], r6 = values[6], r7 = values[7]
            var index = 8
            let blockEnd = count - count % 8
            while index < blockEnd {
                r0 += values[index]
                r1 += values[index + 1]
                r2 += values[index + 2]
                r3 += values[index + 3]
                r4 += values[index + 4]
                r5 += values[index + 5]
                r6 += values[index + 6]
                r7 += values[index + 7]
                index += 8
            }
            var result = ((r0 + r1) + (r2 + r3)) + ((r4 + r5) + (r6 + r7))
            while index < count {
                result += values[index]
                index += 1
            }
            return result
        }
        var half = count / 2
        half -= half % 8
        return pairwiseSum(UnsafeBufferPointer(rebasing: values[..<half]))
            + pairwiseSum(UnsafeBufferPointer(rebasing: values[half...]))
    }

    static func mean(_ values: ArraySlice<Double>) -> Double {
        values.withUnsafeBufferPointer { pairwiseSum($0) / Double($0.count) }
    }
}
