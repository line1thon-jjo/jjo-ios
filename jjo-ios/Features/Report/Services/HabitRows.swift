//
//  HabitRows.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated enum HabitRows {
    static func build(current: ReportOverviewStats, previous: ReportOverviewStats?) -> [HabitRow] {
        var rows: [HabitRow] = []
        for metric in metrics(of: current) {
            if let index = rows.firstIndex(where: { $0.id == metric.id }) {
                rows[index] = metric
            } else {
                rows.append(metric)
            }
        }

        var before: [String: Int] = [:]
        if let previous {
            for metric in metrics(of: previous) {
                before[metric.id] = metric.after
                if !rows.contains(where: { $0.id == metric.id }) {
                    var cleared = metric
                    cleared.after = 0
                    rows.append(cleared)
                }
            }
        }

        return rows
            .map { row in
                var row = row
                row.before = previous == nil ? nil : before[row.id] ?? 0
                return row
            }
            .filter { $0.after > 0 || ($0.before ?? 0) > 0 }
            .stableSorted { lhs, rhs in
                lhs.after != rhs.after ? lhs.after > rhs.after : (lhs.before ?? 0) > (rhs.before ?? 0)
            }
    }

    private static func metrics(of stats: ReportOverviewStats) -> [HabitRow] {
        [
            HabitRow(id: "fast", label: "빠른 구절", unit: "곳", pace: .fast, after: stats.speed.fast),
            HabitRow(id: "slow", label: "느린 구절", unit: "곳", pace: .slow, after: stats.speed.slow)
        ] + stats.habits.map {
            HabitRow(id: $0.type.rawValue, label: ReportCopy.habitName($0.type), unit: "회", pace: nil, after: $0.count)
        }
    }
}
