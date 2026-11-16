//
//  ReportStatusTests.swift
//  jjo-ios-Tests
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation
import Testing
@testable import jjo_ios

struct ReportStatusTests {
    typealias Fixtures = ReportFixtures

    private func info(
        _ status: ReportStatus, reason: String? = nil, result: AnalysisResult? = nil
    ) -> ReportStatusInfo<Int> {
        ReportTransform.statusInfo(
            recordingId: 42, status: status, practiceTitle: "중문이 기말 발표", recordedAt: Date(timeIntervalSince1970: 0),
            attemptNo: 2, durationMs: 3000, failureReason: reason, result: result
        )
    }

    @Test func completedWarnings() {
        let result = Fixtures.result(warnings: ["PARTIAL_ALIGNMENT", "SOMETHING_NEW"])
        let status = info(.completed, result: result)
        #expect(status.failure == nil)
        #expect(status.warnings == [.partialAlignment])
    }

    @Test func failureCode() {
        let status = info(.failed, reason: "NO_SPEECH", result: Fixtures.result(warnings: ["PARTIAL_ALIGNMENT"]))
        #expect(status.failure == ReportFailure(code: .noSpeech))
        #expect(status.warnings.isEmpty)
    }

    @Test(arguments: [nil, "", "UNKNOWN_CODE"])
    func failureFallsBack(reason: String?) {
        #expect(info(.failed, reason: reason).failure == ReportFailure(code: .internal))
    }

    @Test(arguments: [ReportStatus.pending, .analyzing])
    func progressHasNothing(status: ReportStatus) {
        let info = info(status, reason: "NO_SPEECH", result: Fixtures.result(warnings: ["PITCH_UNAVAILABLE"]))
        #expect(info.failure == nil && info.warnings.isEmpty)
    }

    @Test func rejectsMajorVersion() {
        #expect(!ReportTransform.isSupportedVersion(Fixtures.result(version: "2.0")))
    }

    @Test func acceptsMinorVersion() {
        #expect(ReportTransform.isSupportedVersion(Fixtures.result(version: "1.2")))
    }

    @Test func attemptsAscending() {
        let date = Date(timeIntervalSince1970: 0)
        let attempts = [
            ReportAttempt(recordingId: 58, attemptNo: 3, recordedAt: date, status: nil),
            ReportAttempt(recordingId: 42, attemptNo: 1, recordedAt: date, status: .completed),
            ReportAttempt(recordingId: 57, attemptNo: 2, recordedAt: date, status: .analyzing)
        ]
        #expect(ReportTransform.attempts(attempts).map(\.recordingId) == [42, 57, 58])
    }

    @Test func overviewUsesFeedback() {
        let result = Fixtures.richResult()
        let stored = StoredFeedback(
            source: .model, model: "m",
            summary: FeedbackSummary(headline: "안정적이었어요.", footer: "끝 올림만 다듬어 보세요."), items: []
        )
        #expect(ReportTransform.overview(result, feedback: stored).summary == stored.summary)
        #expect(ReportTransform.feedback(result, feedback: stored).items.isEmpty)
        #expect(ReportTransform.overview(result, feedback: nil).summary.headline == "전체적으로 무난했어요.")
        #expect(ReportTransform.feedback(result, feedback: nil).items.map(\.rank) == [1, 2, 3])
    }
}
