//
//  HomeEntriesTests.swift
//  jjo-ios-Tests
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation
import Testing
@testable import jjo_ios

struct HomeEntriesTests {
    private let base = Date(timeIntervalSince1970: 1_800_000_000)

    private func attempt(_ number: Int, _ status: ReportStatus?, id: UUID = UUID()) -> HomeEntries.Attempt {
        ReportAttempt(
            recordingId: id, attemptNo: number, recordedAt: base.addingTimeInterval(Double(number) * 60), status: status
        )
    }

    private func entry(_ attempts: [HomeEntries.Attempt], updatedAt: Date? = nil) -> HomeEntry {
        HomeEntries.entry(id: UUID(), title: "제목", script: "대본", updatedAt: updatedAt ?? base, attempts: attempts)
    }

    @Test func handlesUnrecorded() {
        let entry = entry([])
        #expect(entry.attemptCount == 0)
        #expect(entry.latestID == nil)
        #expect(entry.latestCompletedID == nil)
        #expect(entry.activeAt == base)
    }

    @Test func picksLatest() {
        let first = attempt(1, .completed)
        let second = attempt(2, .completed)
        let third = attempt(3, .analyzing)
        let entry = entry([second, third, first])

        #expect(entry.attemptCount == 3)
        #expect(entry.latestID == third.recordingId)
        #expect(entry.latestCompletedID == second.recordingId)
        #expect(entry.previousCompletedID == first.recordingId)
        #expect(entry.activeAt == third.recordedAt)
    }

    @Test func skipsFailed() {
        let first = attempt(1, .completed)
        let third = attempt(3, .completed)
        let entry = entry([first, attempt(2, .failed), third, attempt(4, nil)])

        #expect(entry.latestCompletedID == third.recordingId)
        #expect(entry.previousCompletedID == first.recordingId)
    }

    @Test func sortsRecent() {
        let old = entry([], updatedAt: base.addingTimeInterval(-500))
        let recorded = entry([attempt(1, .completed)])
        let tiedFirst = entry([], updatedAt: base)
        let tiedSecond = entry([], updatedAt: base)

        let sorted = HomeEntries.sorted([old, tiedFirst, recorded, tiedSecond])
        #expect(sorted.map(\.id) == [recorded.id, tiedFirst.id, tiedSecond.id, old.id])
    }
}
