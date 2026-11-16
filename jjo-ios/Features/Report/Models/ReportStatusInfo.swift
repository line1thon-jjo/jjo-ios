//
//  ReportStatusInfo.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated struct ReportStatusInfo<ID: Hashable & Codable & Sendable>: Codable, Equatable, Sendable {
    var recordingId: ID
    var status: ReportStatus
    var practiceTitle: String
    var recordedAt: Date
    var attemptNo: Int
    var durationMs: Int
    var failure: ReportFailure?
    var warnings: [ReportWarning] = []
}
