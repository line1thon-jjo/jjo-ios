//
//  HomeEntries.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated enum HomeEntries {
    typealias Attempt = ReportAttempt<UUID>

    static func entry(id: UUID, title: String, script: String, updatedAt: Date, attempts: [Attempt]) -> HomeEntry {
        let latest = newest(attempts)
        let latestCompleted = newest(attempts.filter { $0.status == .completed })
        let previousCompleted = latestCompleted.flatMap { ReportAttempts.previous(attempts, before: $0.attemptNo) }

        return HomeEntry(
            id: id,
            title: title,
            script: script,
            attemptCount: attempts.count,
            latestID: latest?.recordingId,
            latestCompletedID: latestCompleted?.recordingId,
            previousCompletedID: previousCompleted?.recordingId,
            activeAt: latest?.recordedAt ?? updatedAt
        )
    }

    static func sorted(_ entries: [HomeEntry]) -> [HomeEntry] {
        entries.enumerated()
            .sorted { ($0.element.activeAt, $1.offset) > ($1.element.activeAt, $0.offset) }
            .map(\.element)
    }

    private static func newest(_ attempts: [Attempt]) -> Attempt? {
        attempts.max { $0.attemptNo < $1.attemptNo }
    }
}
