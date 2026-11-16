//
//  RecordTime.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated enum RecordTime {
    static func clock(_ totalSeconds: Int) -> String {
        let total = max(0, totalSeconds)
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    static func spoken(_ totalSeconds: Int) -> String {
        let total = max(0, totalSeconds)
        let minutes = total / 60
        let seconds = total % 60

        if minutes == 0 { return "\(seconds)초" }
        if seconds == 0 { return "\(minutes)분" }
        return "\(minutes)분 \(seconds)초"
    }
}
