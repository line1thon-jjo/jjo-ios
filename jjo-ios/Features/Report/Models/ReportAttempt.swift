//
//  ReportAttempt.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated struct ReportAttempt<ID: Hashable & Codable & Sendable>: Codable, Equatable, Sendable {
    var recordingId: ID
    var attemptNo: Int
    var recordedAt: Date
    var status: ReportStatus?
}
