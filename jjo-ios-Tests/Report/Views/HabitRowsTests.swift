//
//  HabitRowsTests.swift
//  jjo-ios-Tests
//
//  Created by dohyeoplim on 11/16/26.
//

import Testing
@testable import jjo_ios

struct HabitRowsTests {
    private func stats(fast: Int, slow: Int, _ habits: [(HabitType, Int)]) -> ReportOverviewStats {
        ReportOverviewStats(
            speed: SpeedCounts(fast: fast, normal: 8, slow: slow, measured: fast + slow + 8),
            habits: habits.map { HabitCount(type: $0.0, count: $0.1) }
        )
    }

    @Test func sortsByCount() {
        let rows = HabitRows.build(
            current: stats(fast: 5, slow: 2, [(.endRise, 4), (.midStretch, 3), (.midPause, 2)]), previous: nil
        )
        #expect(rows.map(\.id) == ["fast", "END_RISE", "MID_STRETCH", "slow", "MID_PAUSE"])
        #expect(rows.map(\.label) == ["빠른 구절", "끝 올림", "중간 늘임", "느린 구절", "중간 쉼"])
        #expect(rows.map(\.unit) == ["곳", "회", "회", "곳", "회"])
        #expect(rows.allSatisfy { $0.before == nil && $0.difference == nil })
    }

    @Test func comparesPrevious() {
        let rows = HabitRows.build(
            current: stats(fast: 3, slow: 1, [(.midStretch, 3), (.endRise, 2)]),
            previous: stats(fast: 5, slow: 2, [(.endRise, 4), (.midStretch, 3), (.midPause, 2)])
        )
        #expect(rows.map(\.id) == ["fast", "MID_STRETCH", "END_RISE", "slow", "MID_PAUSE"])
        #expect(rows.map(\.after) == [3, 3, 2, 1, 0])
        #expect(rows.map(\.before) == [5, 3, 4, 2, 2])
        #expect(rows.map(\.difference) == [-2, 0, -2, -1, -2])
        #expect(rows.last?.isCleared == true)
    }

    @Test func dropsEmptyRows() {
        #expect(HabitRows.build(current: stats(fast: 0, slow: 0, []), previous: nil).isEmpty)
        #expect(HabitRows.build(current: stats(fast: 0, slow: 0, []), previous: stats(fast: 0, slow: 0, [])).isEmpty)
    }

    @Test func breaksTies() {
        let rows = HabitRows.build(
            current: stats(fast: 2, slow: 2, [(.endFade, 2)]),
            previous: stats(fast: 1, slow: 4, [(.endFade, 2), (.noBreak, 3)])
        )
        #expect(rows.map(\.id) == ["slow", "END_FADE", "fast", "NO_BREAK"])
        #expect(rows.first?.pace == .slow)
        #expect(rows.last?.pace == nil)
    }
}
