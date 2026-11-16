//
//  StoredFeedback.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated enum FeedbackSource: String, Codable, Sendable {
    case model
    case rule
    case mixed
}

nonisolated struct StoredFeedback: Codable, Equatable, Sendable {
    static let currentVersion = 1

    var version = StoredFeedback.currentVersion
    var source: FeedbackSource
    var model: String?
    var summary: FeedbackSummary
    var items: [FeedbackItem]
}
