//
//  NumericParityTests.swift
//  jjo-ios-Tests
//
//  Created by dohyeoplim on 11/16/26.
//

import Testing
@testable import jjo_ios

struct NumericParityTests {
    @Test func roundsLikePython() {
        #expect(PyNumber.round(1.115, digits: 2) == 1.11)
        #expect(PyNumber.round(2.675, digits: 2) == 2.67)
        #expect(PyNumber.round(0.125, digits: 2) == 0.12)
        #expect(PyNumber.round(0.5) == 0)
        #expect(PyNumber.round(1.5) == 2)
        #expect(PyNumber.round(2.5) == 2)
    }

    @Test func roundsLikeNumpy() {
        #expect(NumPy.round(1.115, digits: 2) == 1.12)
        #expect(NumPy.round(2.675, digits: 2) == 2.68)
        #expect(PyNumber(1.115, isNumpy: true).rounded(digits: 2) == 1.12)
        #expect((PyNumber(223) / 200.0).rounded(digits: 2) == 1.11)
        #expect((PyNumber(223, isNumpy: true) / 200.0).rounded(digits: 2) == 1.12)
    }

    @Test func interpolatesPercentiles() {
        let values = [3.0, 1.0, 4.0, 1.5, 9.0, 2.5]
        #expect(NumPy.percentile(values, 5) == 1.125)
        #expect(NumPy.percentile(values, 75) == 3.75)
        #expect(NumPy.percentile(values, 100) == 9.0)
        #expect(NumPy.median(values) == 2.75)
        #expect(NumPy.median([5.0, 1.0, 3.0]) == 3.0)
    }

    @Test func searchesSortedSides() {
        let values = [0.0, 3.0, 3.0, 7.0]
        #expect(NumPy.searchSorted(values, 3.0, right: false) == 1)
        #expect(NumPy.searchSorted(values, 3.0, right: true) == 3)
        #expect(NumPy.searchSorted(values, 8.0, right: true) == 4)
    }

    @Test func sumsLikePython() {
        #expect(PyNumber.sum([0.1, 0.2, 0.3]) == 0.6)
        #expect(PyNumber.sum([1e16, 1.0, -1e16]) == 1.0)
        #expect(PyNumber.sum([PyNumber(1e16), PyNumber(1.0, isNumpy: true), PyNumber(-1e16)]).value == 0.0)
        #expect(PyNumber.floorDivide(-25.0, by: 10) == -3)
        #expect(PyNumber.floorDivide(299.99, by: 10) == 29)
    }

    @Test func keepsPythonOperandOrder() {
        let first = PyNumber(2.0)
        let second = PyNumber(2.0, isNumpy: true)
        #expect(PyNumber.max(first, second).isNumpy == false)
        #expect(PyNumber.min(second, first).isNumpy == true)
        #expect((first + second).isNumpy)
    }
}
