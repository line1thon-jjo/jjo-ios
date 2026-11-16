//
//  ReportContent.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated struct ReportContent: Equatable, Sendable {
    var overview: ReportOverview
    var utterance: UtteranceAnalysis
    var feedback: FeedbackResponse
    var warnings: [ReportWarning]
    var habitRows: [HabitRow]
    var hasPrevious: Bool
    var tokens: [GlyphToken]
    var narration: [UtteranceNarration.Passage]
    var glyphCount: Int
}

nonisolated extension ReportContent {
    nonisolated struct Source: Equatable, Sendable {
        var resultData: Data?
        var feedbackData: Data?
        var previousResultData: Data?
    }

    static func make(_ source: Source) -> ReportContent? {
        guard let result = decode(AnalysisResult.self, from: source.resultData),
              ReportTransform.isSupportedVersion(result)
        else { return nil }

        let stored = decode(StoredFeedback.self, from: source.feedbackData)
        let overview = ReportTransform.overview(result, feedback: stored)
        let utterance = ReportTransform.utterance(result)
        let previous = decode(AnalysisResult.self, from: source.previousResultData)
            .map(ReportTransform.overviewStats)
        let glyphs = GlyphBuilder.build(utterance)

        return ReportContent(
            overview: overview,
            utterance: utterance,
            feedback: ReportTransform.feedback(result, feedback: stored),
            warnings: ReportTransform.warnings(result),
            habitRows: HabitRows.build(
                current: ReportOverviewStats(speed: overview.speed, habits: overview.habits), previous: previous
            ),
            hasPrevious: previous != nil,
            tokens: GlyphBuilder.groupWords(glyphs),
            narration: UtteranceNarration.passages(glyphs),
            glyphCount: glyphs.count
        )
    }

    private static func decode<Value: Decodable>(_ type: Value.Type, from data: Data?) -> Value? {
        data.flatMap { try? JSONDecoder().decode(type, from: $0) }
    }
}
