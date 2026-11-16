//
//  FeedbackRulesTests.swift
//  jjo-ios-Tests
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation
import Testing
@testable import jjo_ios

struct FeedbackRulesTests {
    typealias Fixtures = ReportFixtures

    private static let focusCases: [FeedbackCandidate.Focus] = [
        .init(),
        .init(char: "는", word: "나서는", wordBefore: "답했습니다", wordAfter: "이제"),
        .init(
            char: "다", word: String(repeating: "가", count: 30), wordBefore: String(repeating: "가", count: 30),
            wordAfter: "나"
        )
    ]

    private static let metricsCases: [FeedbackCandidate.Metrics] = [
        .init(durationMs: 99_999, speed: .fast), .init(durationMs: 630, speed: .slow)
    ]

    @Test(arguments: FeedbackKind.allCases)
    func textsFitLimits(kind: FeedbackKind) {
        for focus in Self.focusCases {
            for metrics in Self.metricsCases {
                let candidate = Fixtures.candidate(1, kind, metrics: metrics, focus: focus)
                let texts = (0..<3).map { FeedbackRules.text(for: candidate, variant: $0) }
                #expect(Set(texts.map { $0.title + "\n" + $0.body }).count == 3)
                for text in texts {
                    #expect((1...FeedbackRules.titleMax).contains(text.title.unicodeScalars.count))
                    #expect((1...FeedbackRules.bodyMax).contains(text.body.unicodeScalars.count))
                    #expect(!text.body.contains("{") && !text.body.contains("}"))
                }
            }
        }
        let summary = FeedbackRules.summary(for: [Fixtures.candidate(1, kind)])
        #expect(summary.headline.unicodeScalars.count <= FeedbackRules.headlineMax)
        #expect(summary.footer.unicodeScalars.count <= FeedbackRules.footerMax)
        #expect(FeedbackRules.noIssueSummary.headline.unicodeScalars.count <= FeedbackRules.headlineMax)
        #expect(FeedbackRules.noIssueSummary.footer.unicodeScalars.count <= FeedbackRules.footerMax)
    }

    @Test func namesWordAndPause() {
        let stretch = Fixtures.candidate(1, .midStretch, focus: .init(char: "는", word: "나서는"))
        #expect(FeedbackRules.text(for: stretch).body.hasPrefix("‘나서는’의 ‘는’ 소리가"))
        let single = Fixtures.candidate(3, .midStretch, focus: .init(char: "또", word: "또"))
        #expect(FeedbackRules.text(for: single).body.hasPrefix("‘또’ 소리가"))
        let gap = Fixtures.candidate(
            2, .pause, metrics: .init(durationMs: 630), focus: .init(wordBefore: "저는", wordAfter: "이번")
        )
        #expect(FeedbackRules.text(for: gap).body.hasPrefix("‘저는’ 뒤에서 0.6초"))
    }

    @Test func genericWithoutWord() {
        let candidate = Fixtures.candidate(1, .pause, metrics: .init(durationMs: 630))
        #expect(FeedbackRules.text(for: candidate) == FeedbackRules.generic[.pause]?[0])
        #expect(FeedbackRules.text(for: candidate, variant: 2).body == "0.6초 쉼은 길게 느껴질 수 있어요. 한 박자 정도로 줄여 보세요.")
    }

    @Test func pauseSecondsRounding() {
        let seconds = [630, 650, 1450, 2050, 50, 0].map {
            FeedbackRules.pauseSec(Fixtures.candidate(1, .pause, metrics: .init(durationMs: $0)))
        }
        #expect(seconds == ["0.6", "0.7", "1.4", "2.0", "0.1", nil])
        #expect(FeedbackRules.pauseSec(Fixtures.candidate(1, .pause)) == nil)
    }

    @Test func sameKindDiffers() {
        let candidates = [1, 2, 3].map { Fixtures.candidate($0, .midStretch) }
        let items = FeedbackComposer.ruleFeedback(candidates).items
        #expect(Set(items.map { $0.title + "\n" + $0.body }).count == 3)
    }

    @Test func selectionPrefersDistinct() {
        let kinds: [FeedbackKind] = [.midStretch, .midStretch, .midStretch, .pace, .pause]
        let candidates = kinds.enumerated().map { Fixtures.candidate($0.offset + 1, $0.element) }
        #expect(FeedbackRules.selection(candidates).map(\.id) == [1, 4, 5])
        #expect(FeedbackRules.selection(Array(candidates.prefix(3))).map(\.id) == [1, 2, 3])
    }

    @Test func selectionFillsOrder() {
        let kinds: [FeedbackKind] = [.midStretch, .midStretch, .midStretch, .pace]
        let candidates = kinds.enumerated().map { Fixtures.candidate($0.offset + 1, $0.element) }
        #expect(FeedbackRules.selection(candidates).map(\.id) == [1, 2, 4])
    }

    @Test func summaryNamesFirst() {
        #expect(FeedbackRules.summary(for: []) == FeedbackRules.noIssueSummary)
        let summary = FeedbackRules.summary(for: [Fixtures.candidate(1, .noBreak), Fixtures.candidate(2, .pace)])
        #expect(summary == FeedbackSummary(headline: "전체적으로 무난했어요.", footer: "이어 말하기 부분만 다듬어 보세요."))
    }
}
