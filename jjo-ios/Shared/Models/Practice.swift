//
//  Practice.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation
import SwiftData

@Model
final class Practice {
    @Attribute(.unique) var id: UUID
    var title: String
    var script: String
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Recording.practice)
    var recordings: [Recording] = []

    init(title: String, script: String, now: Date = .now) {
        id = UUID()
        self.title = title
        self.script = script
        createdAt = now
        updatedAt = now
    }

    var attempts: [Recording] {
        recordings.sorted { $0.attemptNo < $1.attemptNo }
    }

    var latestRecording: Recording? {
        recordings.max { $0.attemptNo < $1.attemptNo }
    }
}
