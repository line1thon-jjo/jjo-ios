//
//  PyNumber.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

// numpy float64 의 round(x, n) 은 파이썬 float 과 결과가 달라서(1.115 → 1.12 / 1.11) 값이 어디서 왔는지 함께 들고 다닌다.
nonisolated struct PyNumber: Equatable, Sendable {
    static let zero = PyNumber(0)

    var value: Double
    var isNumpy: Bool

    init(_ value: Double, isNumpy: Bool = false) {
        self.value = value
        self.isNumpy = isNumpy
    }

    init(_ value: Int) {
        self.init(Double(value))
    }

    func rounded(digits: Int) -> Double {
        isNumpy ? NumPy.round(value, digits: digits) : PyNumber.round(value, digits: digits)
    }

    static func round(_ value: Double) -> Int {
        Int(value.rounded(.toNearestOrEven))
    }

    static func round(_ value: Double, digits: Int) -> Double {
        guard value.isFinite else { return value }
        return Double(String(format: "%.\(digits)f", value)) ?? value
    }

    static func floorDivide(_ value: Double, by divisor: Double) -> Double {
        var remainder = fmod(value, divisor)
        var quotient = (value - remainder) / divisor
        if remainder != 0 && (divisor < 0) != (remainder < 0) {
            remainder += divisor
            quotient -= 1
        }
        guard quotient != 0 else { return 0 }
        let floored = quotient.rounded(.down)
        return quotient - floored > 0.5 ? floored + 1 : floored
    }

    // 파이썬 3.12 의 sum() 은 float 을 보정 합산(Neumaier)으로 더한다. numpy 값이 섞이면 그때부터 그냥 더한다.
    static func sum(_ values: [Double]) -> Double {
        sum(values.map { PyNumber($0) }).value
    }

    static func sum(_ values: [PyNumber]) -> PyNumber {
        var result = 0.0
        var compensation = 0.0
        var index = 0
        while index < values.count, !values[index].isNumpy {
            let value = values[index].value
            let total = result + value
            if index > 0 {
                compensation += abs(result) >= abs(value) ? (result - total) + value : (value - total) + result
            }
            result = total
            index += 1
        }
        if compensation != 0 && compensation.isFinite { result += compensation }
        guard index < values.count else { return PyNumber(result) }
        for value in values[index...] { result += value.value }
        return PyNumber(result, isNumpy: true)
    }

    static func max(_ lhs: PyNumber, _ rhs: PyNumber) -> PyNumber {
        rhs.value > lhs.value ? rhs : lhs
    }

    static func min(_ lhs: PyNumber, _ rhs: PyNumber) -> PyNumber {
        rhs.value < lhs.value ? rhs : lhs
    }

    static func + (lhs: PyNumber, rhs: PyNumber) -> PyNumber {
        PyNumber(lhs.value + rhs.value, isNumpy: lhs.isNumpy || rhs.isNumpy)
    }

    static func - (lhs: PyNumber, rhs: PyNumber) -> PyNumber {
        PyNumber(lhs.value - rhs.value, isNumpy: lhs.isNumpy || rhs.isNumpy)
    }

    static func * (lhs: PyNumber, rhs: PyNumber) -> PyNumber {
        PyNumber(lhs.value * rhs.value, isNumpy: lhs.isNumpy || rhs.isNumpy)
    }

    static func / (lhs: PyNumber, rhs: PyNumber) -> PyNumber {
        PyNumber(lhs.value / rhs.value, isNumpy: lhs.isNumpy || rhs.isNumpy)
    }

    static func + (lhs: PyNumber, rhs: Double) -> PyNumber {
        PyNumber(lhs.value + rhs, isNumpy: lhs.isNumpy)
    }

    static func - (lhs: PyNumber, rhs: Double) -> PyNumber {
        PyNumber(lhs.value - rhs, isNumpy: lhs.isNumpy)
    }

    static func * (lhs: PyNumber, rhs: Double) -> PyNumber {
        PyNumber(lhs.value * rhs, isNumpy: lhs.isNumpy)
    }

    static func / (lhs: PyNumber, rhs: Double) -> PyNumber {
        PyNumber(lhs.value / rhs, isNumpy: lhs.isNumpy)
    }

    static func / (lhs: Double, rhs: PyNumber) -> PyNumber {
        PyNumber(lhs / rhs.value, isNumpy: rhs.isNumpy)
    }
}
