//
//  GreetingTests.swift
//  jjo-ios-Tests
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation
import Testing
@testable import jjo_ios

struct GreetingTests {
    @Test(arguments: [
        (5, "좋은 아침이에요"), (10, "좋은 아침이에요"), (11, "좋은 오후예요"), (16, "좋은 오후예요"),
        (17, "좋은 저녁이에요"), (21, "좋은 저녁이에요"), (22, "늦은 시간까지 수고 많아요"), (23, "늦은 시간까지 수고 많아요")
    ])
    func picksSlot(hour: Int, expected: String) {
        #expect(Greeting.text(hour: hour) == expected)
    }

    @Test(arguments: [0, 4])
    func wrapsNight(hour: Int) {
        #expect(Greeting.text(hour: hour) == "늦은 시간까지 수고 많아요")
    }

    @Test func readsCalendar() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Asia/Seoul"))
        let date = try #require(calendar.date(from: DateComponents(year: 2026, month: 11, day: 16, hour: 9)))
        #expect(Greeting.text(at: date, calendar: calendar) == "좋은 아침이에요")
    }
}
