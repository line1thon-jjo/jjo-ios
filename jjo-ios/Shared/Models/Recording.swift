//
//  Recording.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation
import SwiftData

@Model
final class Recording {
    @Attribute(.unique) var id: UUID
    var attemptNo: Int
    var scriptSnapshot: String
    var fileName: String
    var durationMs: Int
    var createdAt: Date
    var practice: Practice?

    @Relationship(deleteRule: .cascade, inverse: \Report.recording)
    var report: Report?

    init(attemptNo: Int, scriptSnapshot: String, fileName: String, durationMs: Int, now: Date = .now) {
        id = UUID()
        self.attemptNo = attemptNo
        self.scriptSnapshot = scriptSnapshot
        self.fileName = fileName
        self.durationMs = durationMs
        createdAt = now
    }
}
