//
//  ReportAttemptsTests.swift
//  jjo-ios-Tests
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation
import Testing
@testable import jjo_ios

struct ReportAttemptsTests {
    private func attempt(_ attemptNo: Int, _ status: ReportStatus?) -> ReportAttempt<Int> {
        ReportAttempt(
            recordingId: attemptNo * 10,
            attemptNo: attemptNo,
            recordedAt: Date(timeIntervalSince1970: 0),
            status: status
        )
    }

    @Test(arguments: [
        (0, "0초"), (499, "0초"), (500, "1초"), (53000, "53초"), (59499, "59초"), (59500, "1분"),
        (60000, "1분"), (61000, "1분 1초"), (600_000, "10분"), (3_661_400, "61분 1초")
    ])
    func formatsDuration(durationMs: Int, expected: String) {
        #expect(ReportAttempts.formatDuration(durationMs) == expected)
    }

    @Test func picksLatestCompleted() {
        let attempts = [attempt(3, .completed), attempt(1, .completed), attempt(2, .completed), attempt(4, .completed)]
        #expect(ReportAttempts.previous(attempts, before: 4)?.attemptNo == 3)
        #expect(ReportAttempts.previous(attempts, before: 3)?.attemptNo == 2)
    }

    @Test func skipsUnfinished() {
        let attempts = [attempt(1, .completed), attempt(2, .failed), attempt(3, .analyzing), attempt(4, nil)]
        #expect(ReportAttempts.previous(attempts, before: 5)?.attemptNo == 1)
    }

    @Test func firstHasNone() {
        #expect(ReportAttempts.previous([attempt(1, .completed)], before: 1) == nil)
        #expect(ReportAttempts.previous([ReportAttempt<Int>](), before: 3) == nil)
    }
}
