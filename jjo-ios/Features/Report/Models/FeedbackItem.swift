//
//  FeedbackItem.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated struct FeedbackItem: Codable, Equatable, Sendable {
    var rank: Int
    var title: String
    var quote: String
    var body: String
    var startMs: Int
    var endMs: Int
    var startIdx: Int
    var endIdx: Int
    var kind: FeedbackKind
}
