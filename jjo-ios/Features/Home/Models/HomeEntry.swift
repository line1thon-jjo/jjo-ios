//
//  HomeEntry.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated struct HomeEntry: Identifiable, Equatable, Sendable {
    var id: UUID
    var title: String
    var script: String
    var attemptCount: Int
    var latestID: UUID?
    var latestCompletedID: UUID?
    var previousCompletedID: UUID?
    var activeAt: Date
}
