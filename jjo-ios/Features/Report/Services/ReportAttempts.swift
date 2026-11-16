//
//  ReportAttempts.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated enum ReportAttempts {
    static func formatDuration(_ durationMs: Int) -> String {
        let totalSeconds = Int((Double(durationMs) / 1000 + 0.5).rounded(.down))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60

        if minutes == 0 { return "\(seconds)초" }
        if seconds == 0 { return "\(minutes)분" }
        return "\(minutes)분 \(seconds)초"
    }

    static func previous<ID>(_ attempts: [ReportAttempt<ID>], before attemptNo: Int) -> ReportAttempt<ID>? {
        attempts
            .filter { $0.attemptNo < attemptNo && $0.status == .completed }
            .reduce(nil) { latest, attempt in
                guard let latest, attempt.attemptNo <= latest.attemptNo else { return attempt }
                return latest
            }
    }
}
