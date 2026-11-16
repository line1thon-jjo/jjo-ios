//
//  PracticeSummaryLoader.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated enum PracticeSummaryLoader {
    struct Payload: Sendable {
        var result: Data
        var feedback: Data?
    }

    @concurrent
    static func load(current: Payload, previous: Payload?) async -> PracticeSummary? {
        summary(current: current, previous: previous)
    }

    static func summary(current: Payload, previous: Payload?) -> PracticeSummary? {
        let decoder = JSONDecoder()
        guard let result = try? decoder.decode(AnalysisResult.self, from: current.result) else { return nil }
        let feedback = current.feedback.flatMap { try? decoder.decode(StoredFeedback.self, from: $0) }
        let overview = ReportTransform.overview(result, feedback: feedback)
        let before = previous
            .flatMap { try? decoder.decode(AnalysisResult.self, from: $0.result) }
            .map(ReportTransform.overviewStats)

        return PracticeSummary(
            summary: overview.summary,
            rows: HabitRows.build(
                current: ReportOverviewStats(speed: overview.speed, habits: overview.habits),
                previous: before
            )
        )
    }
}
