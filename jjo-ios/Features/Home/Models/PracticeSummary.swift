//
//  PracticeSummary.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated struct PracticeSummary: Equatable, Sendable {
    var summary: FeedbackSummary
    var rows: [HabitRow]
}
