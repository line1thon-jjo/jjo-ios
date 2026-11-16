//
//  RecordTimeTests.swift
//  jjo-ios-Tests
//
//  Created by dohyeoplim on 11/16/26.
//

import Testing
@testable import jjo_ios

struct RecordTimeTests {
    @Test(arguments: [(0, "00:00"), (5, "00:05"), (65, "01:05"), (595, "09:55"), (-3, "00:00")])
    func formatsClock(seconds: Int, expected: String) {
        #expect(RecordTime.clock(seconds) == expected)
    }

    @Test(arguments: [(0, "0초"), (42, "42초"), (60, "1분"), (65, "1분 5초"), (595, "9분 55초")])
    func speaksDuration(seconds: Int, expected: String) {
        #expect(RecordTime.spoken(seconds) == expected)
    }
}
