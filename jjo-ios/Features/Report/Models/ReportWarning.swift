//
//  ReportWarning.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated enum ReportWarning: String, Codable, Sendable, CaseIterable {
    case scriptDeviation = "SCRIPT_DEVIATION"
    case partialAlignment = "PARTIAL_ALIGNMENT"
    case pitchUnavailable = "PITCH_UNAVAILABLE"
}
