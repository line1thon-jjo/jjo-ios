//
//  ReportCodingTests.swift
//  jjo-ios-Tests
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation
import Testing
@testable import jjo_ios

struct ReportCodingTests {
    typealias Fixtures = ReportFixtures

    private func object(_ value: some Encodable) throws -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        let decoded = try JSONSerialization.jsonObject(with: encoder.encode(value))
        return try #require(decoded as? [String: Any])
    }

    private func keys(_ value: Any?) -> Set<String> {
        Set((value as? [String: Any] ?? [:]).keys)
    }

    private func first(_ value: Any?) -> Any? {
        (value as? [Any])?.first
    }

    @Test func utteranceKeys() throws {
        let result = Fixtures.result(
            "가나다라마 바사아자차",
            syllables: [
                Fixtures.syllable(1, "나", pitchLevel: 7),
                Fixtures.syllable(4, "마", stretch: true, stretchRatio: 2.9),
                Fixtures.syllable(6, "바"), Fixtures.syllable(7, "사"), Fixtures.syllable(8, "아")
            ],
            pauses: [Fixtures.pause(8, 800)],
            phrases: [Fixtures.phrase(0, 4, .fast)],
            unclearRanges: [UnclearRange(startIdx: 9, endIdx: 10, reason: .skipped, confidence: 0.9)],
            spokenDifferences: [
                SpokenDifference(kind: .replaced, startIdx: 0, endIdx: 1, spoken: "가나", scriptText: "다라"),
                SpokenDifference(kind: .added, startIdx: 2, endIdx: 3, spoken: "다라")
            ]
        )
        let json = try object(ReportTransform.utterance(result))
        #expect(Set(json.keys) == [
            "spoken_text", "marks", "paces", "pauses", "segments", "replaced", "added", "skipped"
        ])
        let marks = try #require(json["marks"] as? [[String: Any]])
        #expect(marks.map { Set($0.keys) } == [["idx", "pitch"], ["idx", "stretch"]])
        #expect(keys(first(json["paces"])) == ["start_idx", "end_idx", "label"])
        #expect(keys(first(json["pauses"])) == ["after_idx", "duration_ms"])
        #expect(keys(first(json["segments"])) == ["start_idx", "end_idx", "start_ms", "end_ms"])
        #expect(keys(first(json["replaced"])) == ["start_idx", "end_idx", "spoken", "script_text"])
        #expect(keys(first(json["added"])) == ["start_idx", "end_idx", "spoken"])
        #expect(keys(first(json["skipped"])) == ["start_idx", "end_idx"])
    }

    @Test func overviewKeys() throws {
        let json = try object(ReportTransform.overview(Fixtures.richResult(), feedback: nil))
        #expect(Set(json.keys) == ["summary", "speed", "habits"])
        #expect(keys(json["summary"]) == ["headline", "footer"])
        #expect(keys(json["speed"]) == ["fast", "normal", "slow", "measured"])
        #expect(keys(first(json["habits"])) == ["type", "count"])
    }

    @Test func feedbackKeys() throws {
        let stored = FeedbackComposer.compose(
            result: Fixtures.richResult(), draft: FeedbackDraft(headline: "좋았어요.", footer: "다듬어요."), model: "m"
        )
        let json = try object(stored)
        #expect(Set(json.keys) == ["version", "source", "model", "summary", "items"])
        #expect(json["version"] as? Int == 1)
        #expect(json["source"] as? String == "mixed")
        #expect(keys(first(json["items"])) == [
            "rank", "title", "quote", "body", "start_ms", "end_ms", "start_idx", "end_idx", "kind"
        ])
    }

    @Test func statusKeys() throws {
        let completed = ReportTransform.statusInfo(
            recordingId: 42, status: .completed, practiceTitle: "제목", recordedAt: Date(timeIntervalSince1970: 0),
            attemptNo: 1, durationMs: 56640, result: Fixtures.result(warnings: ["SCRIPT_DEVIATION"])
        )
        let json = try object(completed)
        #expect(Set(json.keys) == [
            "recording_id", "status", "practice_title", "recorded_at", "attempt_no", "duration_ms", "warnings"
        ])
        #expect(json["status"] as? String == "COMPLETED")
        #expect(json["recorded_at"] as? String == "1970-01-01T00:00:00Z")
        #expect(json["warnings"] as? [String] == ["SCRIPT_DEVIATION"])

        let failed = ReportTransform.statusInfo(
            recordingId: 42, status: .failed, practiceTitle: "제목", recordedAt: Date(timeIntervalSince1970: 0),
            attemptNo: 1, durationMs: 56640, failureReason: "AUDIO_TOO_SHORT"
        )
        #expect(try object(failed)["failure"] as? [String: String] == ["code": "AUDIO_TOO_SHORT"])
    }

    @Test func attemptKeys() throws {
        let attempt = ReportAttempt(
            recordingId: 57, attemptNo: 2, recordedAt: Date(timeIntervalSince1970: 0), status: .analyzing
        )
        #expect(Set(try object(attempt).keys) == ["recording_id", "attempt_no", "recorded_at", "status"])
    }

    @Test func candidateKeys() throws {
        let candidates = FeedbackCandidates.build(from: Fixtures.richResult())
        let stretch = try object(try #require(candidates.first))
        #expect(Set(stretch.keys) == [
            "id", "kind", "quote", "start_idx", "end_idx", "start_ms", "end_ms", "metrics", "focus"
        ])
        #expect(keys(stretch["metrics"]) == ["habit_count", "stretch_ratio"])
        #expect(keys(stretch["focus"]) == ["char", "word"])
        #expect(keys(try object(candidates[2])["metrics"]) == ["speed", "speed_ratio"])
        #expect(keys(try object(candidates[2])["focus"]) == ["phrase"])
        #expect(keys(try object(candidates[3])["metrics"]) == ["duration_ms"])
        #expect(keys(try object(candidates[3])["focus"]) == ["word_before", "word_after"])
    }

    @Test func storedRoundTrip() throws {
        let stored = FeedbackComposer.compose(result: Fixtures.richResult(), draft: nil)
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        #expect(try decoder.decode(StoredFeedback.self, from: encoder.encode(stored)) == stored)
        #expect(try JSONDecoder().decode(StoredFeedback.self, from: JSONEncoder().encode(stored)) == stored)
    }
}
