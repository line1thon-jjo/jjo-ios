//
//  PracticeSummaryLoaderTests.swift
//  jjo-ios-Tests
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation
import Testing
@testable import jjo_ios

struct PracticeSummaryLoaderTests {
    private func payload(_ result: AnalysisResult) throws -> PracticeSummaryLoader.Payload {
        PracticeSummaryLoader.Payload(result: try JSONEncoder().encode(result), feedback: nil)
    }

    @Test func comparesPrevious() throws {
        let current = ReportFixtures.result(habits: [ReportFixtures.habit(.midStretch, count: 3)])
        let previous = ReportFixtures.result(
            habits: [ReportFixtures.habit(.midStretch, count: 3), ReportFixtures.habit(.endRise, count: 2)]
        )
        let summary = try #require(
            PracticeSummaryLoader.summary(current: try payload(current), previous: try payload(previous))
        )

        #expect(summary.rows.map(\.id) == ["MID_STRETCH", "END_RISE"])
        #expect(summary.rows.map(\.difference) == [0, -2])
        #expect(!summary.summary.headline.isEmpty)
    }

    @Test func omitsTrend() throws {
        let current = ReportFixtures.result(habits: [ReportFixtures.habit(.midStretch, count: 2)])
        let summary = try #require(PracticeSummaryLoader.summary(current: try payload(current), previous: nil))
        #expect(summary.rows.map(\.before) == [nil])
    }

    @Test func rejectsCorrupt() {
        let broken = PracticeSummaryLoader.Payload(result: Data("{}".utf8), feedback: nil)
        #expect(PracticeSummaryLoader.summary(current: broken, previous: nil) == nil)
    }
}
