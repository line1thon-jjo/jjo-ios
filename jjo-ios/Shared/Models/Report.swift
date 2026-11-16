//
//  Report.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation
import SwiftData

nonisolated enum ReportStatus: String, Codable, Sendable {
    case pending = "PENDING"
    case analyzing = "ANALYZING"
    case completed = "COMPLETED"
    case failed = "FAILED"

    var isInProgress: Bool { self == .pending || self == .analyzing }
}

@Model
final class Report {
    var statusValue: String
    var resultData: Data?
    var feedbackData: Data?
    var schemaVersion: String?
    var failureCode: String?
    var createdAt: Date
    var completedAt: Date?
    var recording: Recording?

    init(status: ReportStatus = .pending, now: Date = .now) {
        statusValue = status.rawValue
        createdAt = now
    }

    var status: ReportStatus {
        get { ReportStatus(rawValue: statusValue) ?? .failed }
        set { statusValue = newValue.rawValue }
    }

    var result: AnalysisResult? {
        resultData.flatMap { try? JSONDecoder().decode(AnalysisResult.self, from: $0) }
    }
}
