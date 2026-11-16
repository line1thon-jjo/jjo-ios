//
//  ReportFixtures.swift
//  jjo-ios-Tests
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation
@testable import jjo_ios

nonisolated enum ReportFixtures {
    static let text = "안녕하세요 여러분, 오늘은 발표를 시작하겠습니다. 첫째로 문제를 말씀드리고 둘째로 해결 방법을 보여 드리겠습니다."

    static func result(
        _ text: String = text,
        syllables: [Syllable]? = nil,
        pauses: [Pause] = [],
        phrases: [Phrase] = [],
        habits: [Habit] = [],
        stretched: [Int: Double] = [:],
        unclearRanges: [UnclearRange] = [],
        spokenDifferences: [SpokenDifference] = [],
        warnings: [String] = [],
        version: String = AnalysisResult.schemaVersion
    ) -> AnalysisResult {
        AnalysisResult(
            version: version,
            durationMs: text.unicodeScalars.count * 100,
            spokenText: text,
            syllables: syllables ?? hangulSyllables(text, stretched: stretched),
            pauses: pauses,
            phrases: phrases,
            habits: habits,
            unclearRanges: unclearRanges,
            spokenDifferences: spokenDifferences,
            warnings: warnings,
            summary: AnalysisSummary(avgSyllablesPerSec: 5.0, articulationSyllablesPerSec: 6.0, alignedRatio: 1.0)
        )
    }

    static func hangulSyllables(_ text: String, stretched: [Int: Double] = [:]) -> [Syllable] {
        text.unicodeScalars.enumerated().compactMap { index, scalar in
            guard ("가"..."힣").contains(scalar) else { return nil }
            var syllable = syllable(index, String(scalar))
            if let ratio = stretched[index] {
                syllable.stretch = true
                syllable.stretchRatio = ratio
            }
            return syllable
        }
    }

    static func syllable(
        _ idx: Int, _ char: String, pitchLevel: Int = 4, stretch: Bool = false, stretchRatio: Double = 1.0
    ) -> Syllable {
        Syllable(
            idx: idx, char: char, startMs: idx * 100, endMs: idx * 100 + 100, pitchLevel: pitchLevel,
            stretch: stretch, stretchRatio: stretchRatio
        )
    }

    static func phrase(_ start: Int, _ end: Int, _ label: SpeedLabel, ratio: Double = 1.0) -> Phrase {
        Phrase(startIdx: start, endIdx: end, speedSyllPerSec: 5.0, speedRatio: ratio, speedLabel: label)
    }

    static func pause(_ after: Int, _ durationMs: Int, expected: Bool = false, relative: Double = 1.0) -> Pause {
        Pause(afterIdx: after, durationMs: durationMs, boundary: .word, expected: expected, relativeLength: relative)
    }

    static func habit(_ type: HabitType, _ indices: Int...) -> Habit {
        Habit(
            type: type,
            count: indices.count,
            occurrences: indices.map { IdxRange(startIdx: $0, endIdx: $0) },
            firstIdx: indices.first ?? 0
        )
    }

    static func habit(_ type: HabitType, count: Int) -> Habit {
        Habit(type: type, count: count, occurrences: [IdxRange(startIdx: 0, endIdx: 1)], firstIdx: 0)
    }

    static func index(of word: String, in text: String = text, offset: Int = 0) -> Int {
        guard let range = text.range(of: word) else { return -1 }
        return text.unicodeScalars.distance(from: text.unicodeScalars.startIndex, to: range.lowerBound) + offset
    }

    static func slice(_ text: String, _ start: Int, _ end: Int) -> String {
        ScalarText(text).string(from: start, to: end + 1)
    }

    static func candidate(
        _ id: Int,
        _ kind: FeedbackKind,
        metrics: FeedbackCandidate.Metrics = .init(),
        focus: FeedbackCandidate.Focus = .init()
    ) -> FeedbackCandidate {
        FeedbackCandidate(
            id: id, kind: kind, quote: "q", startIdx: id, endIdx: id, startMs: 0, endMs: 100, metrics: metrics,
            focus: focus
        )
    }

    // 후보 4개: 늘임 2, 빠른 구절 1, 쉼 1
    static func richResult() -> AnalysisResult {
        let first = index(of: "시작하겠습니다", offset: 2)
        let second = index(of: "해결", offset: 1)
        return result(
            pauses: [pause(index(of: "여러분", offset: 2), 900)],
            phrases: [phrase(index(of: "첫째로"), index(of: "말씀드리고", offset: 4), .fast, ratio: 1.5)],
            habits: [habit(.midStretch, first, second)],
            stretched: [first: 2.5, second: 3.0]
        )
    }
}
