//
//  RelativeTime.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated enum RelativeTime {
    private static let minute: TimeInterval = 60
    private static let hour: TimeInterval = 60 * minute
    private static let day: TimeInterval = 24 * hour

    static func text(for date: Date, now: Date = .now, calendar: Calendar = .current) -> String {
        let elapsed = max(0, now.timeIntervalSince(date))

        if elapsed < minute { return "방금 전" }
        if elapsed < hour { return "\(Int(elapsed / minute))분 전" }
        if elapsed < day { return "\(Int(elapsed / hour))시간 전" }
        if elapsed < 7 * day { return "\(Int(elapsed / day))일 전" }

        let parts = calendar.dateComponents([.month, .day], from: date)
        return "\(parts.month ?? 1)월 \(parts.day ?? 1)일"
    }
}
