//
//  ReportTransform.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated enum ReportTransform {
    static let markPitchLevels: Set<Int> = [1, 2, 6, 7]
    static let midPauseMinMs = 400
    static let longPauseMinMs = 700
    static let longPauseMinRelative = 2.0
    static let skippedMinLength = 2
    static let maxHabits = 7
    static let minHabitCount = 2
    static let segmentCutPauseMs = 200
    static let segmentMinSyllables = 4
    private static let segmentCutScalars: Set<Unicode.Scalar> = [",", ".", "?", "!", "\n"]

    static func marks(_ result: AnalysisResult) -> [UtteranceAnalysis.Mark] {
        result.syllables
            .compactMap { syllable -> UtteranceAnalysis.Mark? in
                let pitch = markPitchLevels.contains(syllable.pitchLevel) ? syllable.pitchLevel : nil
                let stretch = syllable.stretch ? syllable.stretchRatio : nil
                guard pitch != nil || stretch != nil else { return nil }
                return UtteranceAnalysis.Mark(idx: syllable.idx, pitch: pitch, stretch: stretch)
            }
            .stableSorted(by: \.idx)
    }

    static func paces(_ result: AnalysisResult) -> [UtteranceAnalysis.Pace] {
        result.phrases
            .compactMap { phrase -> UtteranceAnalysis.Pace? in
                let label: UtteranceAnalysis.PaceLabel? = switch phrase.speedLabel {
                case .fast: .fast
                case .slow: .slow
                case .normal: nil
                }
                return label.map { UtteranceAnalysis.Pace(startIdx: phrase.startIdx, endIdx: phrase.endIdx, label: $0) }
            }
            .stableSorted(by: \.startIdx)
    }

    static func speedCounts(_ result: AnalysisResult) -> SpeedCounts {
        let fast = result.phrases.count { $0.speedLabel == .fast }
        let normal = result.phrases.count { $0.speedLabel == .normal }
        let slow = result.phrases.count { $0.speedLabel == .slow }
        return SpeedCounts(fast: fast, normal: normal, slow: slow, measured: fast + normal + slow)
    }

    static func habits(_ result: AnalysisResult) -> [HabitCount] {
        let habits = result.habits
            .filter { $0.count >= minHabitCount }
            .map { HabitCount(type: $0.type, count: $0.count) }
            .stableSorted { $0.count > $1.count }
        return Array(habits.prefix(maxHabits))
    }

    // 엔진의 isHabit(2번 이상 반복)과 상관없이 한 번만 있어도 보여줄 쉼인지 판단한다
    static func isNotablePause(_ pause: Pause) -> Bool {
        if pause.expected {
            return pause.durationMs >= longPauseMinMs && pause.relativeLength >= longPauseMinRelative
        }
        return pause.durationMs >= midPauseMinMs
    }

    static func pauses(_ result: AnalysisResult) -> [UtteranceAnalysis.NotablePause] {
        result.pauses
            .filter(isNotablePause)
            .map { UtteranceAnalysis.NotablePause(afterIdx: $0.afterIdx, durationMs: $0.durationMs) }
            .stableSorted(by: \.afterIdx)
    }

    static func replaced(_ result: AnalysisResult) -> [UtteranceAnalysis.Replaced] {
        result.spokenDifferences
            .filter { $0.kind == .replaced }
            .map {
                UtteranceAnalysis.Replaced(
                    startIdx: $0.startIdx, endIdx: $0.endIdx, spoken: $0.spoken, scriptText: $0.scriptText
                )
            }
            .stableSorted(by: \.startIdx)
    }

    static func added(_ result: AnalysisResult) -> [UtteranceAnalysis.Added] {
        result.spokenDifferences
            .filter { $0.kind == .added }
            .map { UtteranceAnalysis.Added(startIdx: $0.startIdx, endIdx: $0.endIdx, spoken: $0.spoken) }
            .stableSorted(by: \.startIdx)
    }

    static func skipped(_ result: AnalysisResult) -> [UtteranceAnalysis.Skipped] {
        result.unclearRanges
            .filter { $0.reason == .skipped && $0.endIdx - $0.startIdx + 1 >= skippedMinLength }
            .map { UtteranceAnalysis.Skipped(startIdx: $0.startIdx, endIdx: $0.endIdx) }
            .stableSorted(by: \.startIdx)
    }

    // 엔진의 phrases 는 속도를 못 잰 구절을 빼서 본문을 다 덮지 못하므로 직접 빈틈없이 나눈다
    static func segments(_ result: AnalysisResult) -> [UtteranceAnalysis.Segment] {
        let text = ScalarText(result.spokenText)
        let count = text.count
        let syllables = result.syllables.stableSorted(by: \.idx)
        guard count > 0, !syllables.isEmpty else { return [] }

        var cuts: Set<Int> = []
        for (index, scalar) in text.scalars.enumerated() where segmentCutScalars.contains(scalar) {
            cuts.insert(extendOverTrailing(text, index))
        }
        for pause in result.pauses where pause.durationMs >= segmentCutPauseMs && (0..<count).contains(pause.afterIdx) {
            cuts.insert(extendOverTrailing(text, pause.afterIdx))
        }

        var ranges: [(start: Int, end: Int)] = []
        var start = 0
        for cut in cuts.sorted() where cut < count - 1 {
            ranges.append((start, cut))
            start = cut + 1
        }
        ranges.append((start, count - 1))

        var merged: [(start: Int, end: Int)] = []
        // 첫 구절들이 작을 때 뒤 구절로 넘겨 합친다
        var carryStart: Int?
        for range in ranges {
            let rangeStart = carryStart ?? range.start
            carryStart = nil
            let syllableCount = syllables.count { rangeStart <= $0.idx && $0.idx <= range.end }
            if syllableCount >= segmentMinSyllables {
                merged.append((rangeStart, range.end))
            } else if let last = merged.last {
                merged[merged.count - 1] = (last.start, range.end)
            } else {
                carryStart = rangeStart
            }
        }
        if let carryStart {
            merged.append((carryStart, count - 1))
        }

        return merged.compactMap { range -> UtteranceAnalysis.Segment? in
            let inside = syllables.filter { range.start <= $0.idx && $0.idx <= range.end }
            guard let startMs = inside.map(\.startMs).min(), let endMs = inside.map(\.endMs).max() else { return nil }
            return UtteranceAnalysis.Segment(startIdx: range.start, endIdx: range.end, startMs: startMs, endMs: endMs)
        }
    }

    static func overviewStats(_ result: AnalysisResult) -> ReportOverviewStats {
        ReportOverviewStats(speed: speedCounts(result), habits: habits(result))
    }

    static func overview(_ result: AnalysisResult, feedback: StoredFeedback?) -> ReportOverview {
        ReportOverview(
            summary: FeedbackComposer.load(feedback, result: result).summary,
            speed: speedCounts(result),
            habits: habits(result)
        )
    }

    static func utterance(_ result: AnalysisResult) -> UtteranceAnalysis {
        UtteranceAnalysis(
            spokenText: result.spokenText,
            marks: marks(result),
            paces: paces(result),
            pauses: pauses(result),
            segments: segments(result),
            replaced: replaced(result),
            added: added(result),
            skipped: skipped(result)
        )
    }

    static func feedback(_ result: AnalysisResult, feedback: StoredFeedback?) -> FeedbackResponse {
        FeedbackResponse(items: FeedbackComposer.load(feedback, result: result).items)
    }

    static func warnings(_ result: AnalysisResult) -> [ReportWarning] {
        result.warnings.compactMap(ReportWarning.init(rawValue:))
    }

    static func isSupportedVersion(_ result: AnalysisResult) -> Bool {
        majorVersion(result.version) == majorVersion(AnalysisResult.schemaVersion)
    }

    static func statusInfo<ID>(
        recordingId: ID,
        status: ReportStatus,
        practiceTitle: String,
        recordedAt: Date,
        attemptNo: Int,
        durationMs: Int,
        failureReason: String? = nil,
        result: AnalysisResult? = nil
    ) -> ReportStatusInfo<ID> {
        ReportStatusInfo(
            recordingId: recordingId,
            status: status,
            practiceTitle: practiceTitle,
            recordedAt: recordedAt,
            attemptNo: attemptNo,
            durationMs: durationMs,
            failure: status == .failed ? ReportFailure(reason: failureReason) : nil,
            warnings: status == .completed ? result.map(warnings) ?? [] : []
        )
    }

    static func attempts<ID>(_ attempts: [ReportAttempt<ID>]) -> [ReportAttempt<ID>] {
        attempts.stableSorted(by: \.attemptNo)
    }

    private static func majorVersion(_ version: String) -> String {
        version.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false).first.map(String.init) ?? ""
    }

    private static func extendOverTrailing(_ text: ScalarText, _ index: Int) -> Int {
        var index = index
        while index + 1 < text.count, text[index + 1].isPythonSpace || text[index + 1].isTrailingPunctuation {
            index += 1
        }
        return index
    }
}
