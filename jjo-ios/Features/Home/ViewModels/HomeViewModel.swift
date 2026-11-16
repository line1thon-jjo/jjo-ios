//
//  HomeViewModel.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation
import Observation

@Observable
final class HomeViewModel {
    enum Selection: Equatable {
        case automatic
        case row(UUID)
        case none
    }

    private(set) var entries: [HomeEntry]?
    var selection: Selection = .automatic

    var openID: UUID? {
        switch selection {
        case .automatic: entries?.first?.id
        case .row(let id): id
        case .none: nil
        }
    }

    func load(from store: PracticeStore) {
        entries = HomeEntries.sorted(store.practices().map { practice in
            HomeEntries.entry(
                id: practice.id,
                title: practice.title,
                script: practice.script,
                updatedAt: practice.updatedAt,
                attempts: practice.recordings.map {
                    ReportAttempt(
                        recordingId: $0.id,
                        attemptNo: $0.attemptNo,
                        recordedAt: $0.createdAt,
                        status: $0.report?.status
                    )
                }
            )
        })
    }

    @discardableResult
    func toggle(_ id: UUID) -> Bool {
        let opens = id != openID
        selection = opens ? .row(id) : .none
        return opens
    }

    func summary(for entry: HomeEntry, in store: PracticeStore) async -> PracticeSummary? {
        guard let current = payload(for: entry.latestCompletedID, in: store) else { return nil }
        return await PracticeSummaryLoader.load(
            current: current,
            previous: payload(for: entry.previousCompletedID, in: store)
        )
    }

    private func payload(for recordingID: UUID?, in store: PracticeStore) -> PracticeSummaryLoader.Payload? {
        guard let recordingID, let report = store.recording(id: recordingID)?.report, let result = report.resultData
        else { return nil }
        return PracticeSummaryLoader.Payload(result: result, feedback: report.feedbackData)
    }
}
