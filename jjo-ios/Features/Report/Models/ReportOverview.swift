//
//  ReportOverview.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated struct ReportOverview: Codable, Equatable, Sendable {
    var summary: FeedbackSummary
    var speed: SpeedCounts
    var habits: [HabitCount]
}

nonisolated struct ReportOverviewStats: Codable, Equatable, Sendable {
    var speed: SpeedCounts
    var habits: [HabitCount]
}

nonisolated struct SpeedCounts: Codable, Equatable, Sendable {
    var fast: Int
    var normal: Int
    var slow: Int
    var measured: Int
}

nonisolated struct HabitCount: Codable, Equatable, Sendable {
    var type: HabitType
    var count: Int
}
