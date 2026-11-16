//
//  UtteranceAnalysis.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated struct UtteranceAnalysis: Codable, Equatable, Sendable {
    var spokenText: String
    var marks: [Mark]
    var paces: [Pace]
    var pauses: [NotablePause]
    var segments: [Segment]
    var replaced: [Replaced]
    var added: [Added]
    var skipped: [Skipped]
}

nonisolated extension UtteranceAnalysis {
    nonisolated struct Mark: Codable, Equatable, Sendable {
        var idx: Int
        var pitch: Int?
        var stretch: Double?
    }

    nonisolated enum PaceLabel: String, Codable, Sendable {
        case fast = "FAST"
        case slow = "SLOW"
    }

    nonisolated struct Pace: Codable, Equatable, Sendable {
        var startIdx: Int
        var endIdx: Int
        var label: PaceLabel
    }

    nonisolated struct NotablePause: Codable, Equatable, Sendable {
        var afterIdx: Int
        var durationMs: Int
    }

    nonisolated struct Segment: Codable, Equatable, Sendable {
        var startIdx: Int
        var endIdx: Int
        var startMs: Int
        var endMs: Int
    }

    nonisolated struct Replaced: Codable, Equatable, Sendable {
        var startIdx: Int
        var endIdx: Int
        var spoken: String
        var scriptText: String?
    }

    nonisolated struct Added: Codable, Equatable, Sendable {
        var startIdx: Int
        var endIdx: Int
        var spoken: String
    }

    nonisolated struct Skipped: Codable, Equatable, Sendable {
        var startIdx: Int
        var endIdx: Int
    }
}
