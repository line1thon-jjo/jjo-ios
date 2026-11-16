//
//  FeedbackCandidate.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated struct FeedbackCandidate: Codable, Equatable, Sendable {
    var id: Int
    var kind: FeedbackKind
    var quote: String
    var startIdx: Int
    var endIdx: Int
    var startMs: Int
    var endMs: Int
    var metrics = Metrics()
    var focus = Focus()
}

nonisolated extension FeedbackCandidate {
    nonisolated struct Metrics: Codable, Equatable, Sendable {
        var habitCount: Int?
        var durationMs: Int?
        var stretchRatio: Double?
        var speed: SpeedLabel?
        var speedRatio: Double?
    }

    // 인용 안에서 실제 문제 위치. 글자는 char·word, 글자 뒤 사이는 wordBefore·wordAfter, 구절은 phrase
    nonisolated struct Focus: Codable, Equatable, Sendable {
        var char: String?
        var word: String?
        var wordBefore: String?
        var wordAfter: String?
        var phrase: String?
    }
}
