//
//  PlaybackRange.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated struct PlaybackRange: Hashable, Sendable {
    nonisolated enum Source: Hashable, Sendable {
        case feedback(rank: Int)
        case segment(index: Int)
    }

    var source: Source
    var startMs: Int
    var endMs: Int
}

nonisolated extension PlaybackRange {
    init(_ item: FeedbackItem) {
        self.init(source: .feedback(rank: item.rank), startMs: item.startMs, endMs: item.endMs)
    }

    init(_ segment: UtteranceAnalysis.Segment, index: Int) {
        self.init(source: .segment(index: index), startMs: segment.startMs, endMs: segment.endMs)
    }
}
