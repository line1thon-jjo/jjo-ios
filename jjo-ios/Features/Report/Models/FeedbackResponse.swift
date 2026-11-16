//
//  FeedbackResponse.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated struct FeedbackResponse: Codable, Equatable, Sendable {
    var items: [FeedbackItem]
}
