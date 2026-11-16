//
//  RelativeTimeTests.swift
//  jjo-ios-Tests
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation
import Testing
@testable import jjo_ios

struct RelativeTimeTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test(arguments: [
        (0.0, "방금 전"), (59.0, "방금 전"), (60.0, "1분 전"), (3_599.0, "59분 전"), (3_600.0, "1시간 전"),
        (86_399.0, "23시간 전"), (86_400.0, "1일 전"), (604_799.0, "6일 전")
    ])
    func formatsElapsed(seconds: Double, expected: String) {
        #expect(RelativeTime.text(for: now.addingTimeInterval(-seconds), now: now) == expected)
    }

    @Test func clampsFuture() {
        #expect(RelativeTime.text(for: now.addingTimeInterval(300), now: now) == "방금 전")
    }

    @Test func showsDate() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Asia/Seoul"))
        let date = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 9, hour: 12)))
        let later = date.addingTimeInterval(7 * 86_400)
        #expect(RelativeTime.text(for: date, now: later, calendar: calendar) == "3월 9일")
    }
}
