//
//  ReportTransformTests.swift
//  jjo-ios-Tests
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation
import Testing
@testable import jjo_ios

struct ReportTransformTests {
    typealias Fixtures = ReportFixtures

    @Test func marksExtremes() {
        let syllables = [
            Fixtures.syllable(0, "가", pitchLevel: 4),
            Fixtures.syllable(1, "나", pitchLevel: 7),
            Fixtures.syllable(2, "다", pitchLevel: 3, stretch: true, stretchRatio: 2.8),
            Fixtures.syllable(3, "라", pitchLevel: 1, stretch: true, stretchRatio: 2.3),
            Fixtures.syllable(4, "마", pitchLevel: 5, stretchRatio: 1.9)
        ]
        let marks = ReportTransform.marks(Fixtures.result("가나다라마", syllables: syllables))
        #expect(marks == [
            .init(idx: 1, pitch: 7, stretch: nil),
            .init(idx: 2, pitch: nil, stretch: 2.8),
            .init(idx: 3, pitch: 1, stretch: 2.3)
        ])
    }

    @Test func marksEmpty() {
        #expect(ReportTransform.marks(Fixtures.result("가나다")).isEmpty)
    }

    @Test func pacesSkipNormal() {
        let phrases = [
            Fixtures.phrase(0, 4, .fast), Fixtures.phrase(6, 9, .normal),
            Fixtures.phrase(11, 15, .slow), Fixtures.phrase(17, 20, .normal)
        ]
        let result = Fixtures.result("가", phrases: phrases)
        #expect(ReportTransform.paces(result) == [
            .init(startIdx: 0, endIdx: 4, label: .fast), .init(startIdx: 11, endIdx: 15, label: .slow)
        ])
        #expect(ReportTransform.speedCounts(result) == SpeedCounts(fast: 1, normal: 2, slow: 1, measured: 4))
    }

    @Test func speedCountsEmpty() {
        #expect(ReportTransform.speedCounts(Fixtures.result("가")).measured == 0)
    }

    @Test func habitsSortedLimited() {
        let habits = [
            Fixtures.habit(.endFade, count: 3), Fixtures.habit(.endRise, count: 8),
            Fixtures.habit(.midPause, count: 3), Fixtures.habit(.noBreak, count: 1)
        ]
        #expect(ReportTransform.habits(Fixtures.result("가", habits: habits)) == [
            HabitCount(type: .endRise, count: 8), HabitCount(type: .endFade, count: 3),
            HabitCount(type: .midPause, count: 3)
        ])
    }

    @Test func pausesDisplayRules() {
        let pauses = [
            Fixtures.pause(1, 399),
            Fixtures.pause(2, 400),
            Fixtures.pause(3, 800, expected: true, relative: 1.9),
            Fixtures.pause(4, 699, expected: true, relative: 3.0),
            Fixtures.pause(5, 700, expected: true, relative: 2.0)
        ]
        #expect(ReportTransform.pauses(Fixtures.result("가", pauses: pauses)) == [
            .init(afterIdx: 2, durationMs: 400), .init(afterIdx: 5, durationMs: 700)
        ])
    }

    @Test func scriptDifferences() {
        let differences = [
            SpokenDifference(kind: .added, startIdx: 20, endIdx: 24, spoken: "정말 열심히"),
            SpokenDifference(kind: .replaced, startIdx: 5, endIdx: 11, spoken: "프레젠테이션을", scriptText: "발표를")
        ]
        let unclear = [
            UnclearRange(startIdx: 30, endIdx: 30, reason: .skipped, confidence: 0.9),
            UnclearRange(startIdx: 40, endIdx: 42, reason: .skipped, confidence: 0.9),
            UnclearRange(startIdx: 50, endIdx: 53, reason: .lowVolume, confidence: 0.9)
        ]
        let result = Fixtures.result("가", unclearRanges: unclear, spokenDifferences: differences)
        #expect(ReportTransform.replaced(result) == [
            .init(startIdx: 5, endIdx: 11, spoken: "프레젠테이션을", scriptText: "발표를")
        ])
        #expect(ReportTransform.added(result) == [.init(startIdx: 20, endIdx: 24, spoken: "정말 열심히")])
        #expect(ReportTransform.skipped(result) == [.init(startIdx: 40, endIdx: 42)])
    }

    @Test func segmentsCutPunctuation() {
        let segments = ReportTransform.segments(Fixtures.result("안녕하세요 여러분, 반갑습니다."))
        #expect(segments == [
            .init(startIdx: 0, endIdx: 10, startMs: 0, endMs: 900),
            .init(startIdx: 11, endIdx: 16, startMs: 1100, endMs: 1600)
        ])
    }

    @Test func segmentsCutPause() {
        let result = Fixtures.result("저는 오늘 발표를 시작합니다", pauses: [Fixtures.pause(8, 300)])
        #expect(ranges(ReportTransform.segments(result)) == [[0, 9], [10, 14]])
    }

    @Test func segmentsIgnoreShortPause() {
        let result = Fixtures.result("저는 오늘 발표를 시작합니다", pauses: [Fixtures.pause(8, 199)])
        #expect(ranges(ReportTransform.segments(result)) == [[0, 14]])
    }

    @Test func segmentsMergeForward() {
        let text = "네, 알겠습니다."
        #expect(ranges(ReportTransform.segments(Fixtures.result(text))) == [[0, text.unicodeScalars.count - 1]])
    }

    @Test func segmentsMergeBackward() {
        let text = "오늘 발표를 시작합니다. 네."
        #expect(ranges(ReportTransform.segments(Fixtures.result(text))) == [[0, text.unicodeScalars.count - 1]])
    }

    @Test func segmentsCoverText() {
        let text = "첫 번째 문장입니다.\n두 번째 문장은 조금 더 길게 이어집니다, 그리고 계속됩니다. 마지막입니다!"
        let segments = ReportTransform.segments(Fixtures.result(text, pauses: [Fixtures.pause(30, 500)]))
        #expect(segments.first?.startIdx == 0)
        #expect(segments.last?.endIdx == text.unicodeScalars.count - 1)
        for (previous, current) in zip(segments, segments.dropFirst()) {
            #expect(current.startIdx == previous.endIdx + 1)
        }
    }

    @Test func segmentsEmpty() {
        #expect(ReportTransform.segments(Fixtures.result("")).isEmpty)
        #expect(ReportTransform.segments(Fixtures.result("...", syllables: [])).isEmpty)
    }

    @Test func segmentsCountScalars() {
        let text = "첫 줄입니다.\r\n😀 둘째 줄입니다."
        let segments = ReportTransform.segments(Fixtures.result(text))
        #expect(ranges(segments) == [[0, 8], [9, 18]])
    }

    @Test func buildsTabs() {
        let result = Fixtures.result(
            "안녕하세요 여러분, 반갑습니다.",
            phrases: [Fixtures.phrase(0, 4, .normal)],
            habits: [Fixtures.habit(.endRise, count: 2)]
        )
        let utterance = ReportTransform.utterance(result)
        #expect(utterance.spokenText == "안녕하세요 여러분, 반갑습니다.")
        #expect(utterance.marks.isEmpty && utterance.paces.isEmpty && utterance.pauses.isEmpty)
        #expect(utterance.segments.count == 2)
        let stats = ReportTransform.overviewStats(result)
        #expect(stats.speed.measured == 1)
        #expect(stats.habits.first?.count == 2)
    }

    private func ranges(_ segments: [UtteranceAnalysis.Segment]) -> [[Int]] {
        segments.map { [$0.startIdx, $0.endIdx] }
    }
}
