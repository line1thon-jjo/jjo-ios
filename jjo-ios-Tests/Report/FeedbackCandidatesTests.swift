//
//  FeedbackCandidatesTests.swift
//  jjo-ios-Tests
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation
import Testing
@testable import jjo_ios

struct FeedbackCandidatesTests {
    typealias Fixtures = ReportFixtures

    private let text = Fixtures.text

    @Test func noneFound() {
        #expect(FeedbackCandidates.build(from: Fixtures.result()).isEmpty)
    }

    @Test func occurrenceCandidates() {
        let first = Fixtures.index(of: "시작하겠습니다", offset: 2)
        let second = Fixtures.index(of: "해결", offset: 1)
        let result = Fixtures.result(
            habits: [Fixtures.habit(.midStretch, first, second)], stretched: [first: 2.5, second: 3.0]
        )
        let candidates = FeedbackCandidates.build(from: result)
        #expect(candidates.map(\.kind) == [.midStretch, .midStretch])
        #expect(candidates.first?.metrics.stretchRatio == 3.0)
        for candidate in candidates {
            #expect(candidate.quote == Fixtures.slice(text, candidate.startIdx, candidate.endIdx))
            #expect(candidate.quote.unicodeScalars.count <= FeedbackCandidates.quoteMax)
            #expect(candidate.quote == candidate.quote.pythonStripped())
            let anchor = candidate.metrics.stretchRatio == 2.5 ? first : second
            #expect((candidate.startIdx...candidate.endIdx).contains(anchor))
            let inside = result.syllables.filter { (candidate.startIdx...candidate.endIdx).contains($0.idx) }
            #expect(candidate.startMs == inside.first?.startMs)
            #expect(candidate.endMs == inside.last?.endMs)
        }
    }

    @Test func ordersGroups() {
        let stretch = Fixtures.index(of: "둘째로", offset: 1)
        let result = Fixtures.result(
            pauses: [Fixtures.pause(Fixtures.index(of: "여러분", offset: 2), 900), Fixtures.pause(stretch, 900)],
            phrases: [
                Fixtures.phrase(
                    Fixtures.index(of: "오늘은"), Fixtures.index(of: "시작하겠습니다", offset: 6), .fast, ratio: 1.5
                )
            ],
            habits: [Fixtures.habit(.midStretch, stretch, stretch)]
        )
        let candidates = FeedbackCandidates.build(from: result)
        #expect(candidates.map(\.kind) == [.midStretch, .pace, .pause])
        #expect(Set(candidates.map { [$0.startIdx, $0.endIdx] }).count == candidates.count)
        #expect(candidates.map(\.id) == [1, 2, 3])
    }

    @Test func pausePlaysPast() {
        let after = Fixtures.index(of: "여러분", offset: 2)
        let candidates = FeedbackCandidates.build(from: Fixtures.result(pauses: [Fixtures.pause(after, 800)]))
        #expect(candidates.map(\.kind) == [.pause])
        #expect(candidates.first?.endMs == Fixtures.index(of: "오늘은") * 100 + 100)
    }

    @Test func focusNamesSpot() {
        let stretch = Fixtures.index(of: "시작하겠습니다", offset: 1)
        let result = Fixtures.result(
            pauses: [Fixtures.pause(Fixtures.index(of: "여러분", offset: 3), 900)],
            phrases: [
                Fixtures.phrase(Fixtures.index(of: "첫째로"), Fixtures.index(of: "말씀드리고", offset: 4), .fast, ratio: 1.5)
            ],
            habits: [Fixtures.habit(.midStretch, stretch, stretch)],
            stretched: [stretch: 2.5]
        )
        let candidates = FeedbackCandidates.build(from: result)
        let focus = Dictionary(candidates.map { ($0.kind, $0.focus) }, uniquingKeysWith: { first, _ in first })
        #expect(focus[.midStretch] == .init(char: "작", word: "시작하겠습니다"))
        #expect(focus[.pause] == .init(wordBefore: "여러분", wordAfter: "오늘은"))
        #expect(focus[.pace] == .init(phrase: "첫째로 문제를 말씀드리고"))
    }

    @Test func shortPauseIgnored() {
        let result = Fixtures.result(pauses: [Fixtures.pause(Fixtures.index(of: "여러분", offset: 2), 300)])
        #expect(FeedbackCandidates.build(from: result).isEmpty)
    }

    @Test func quoteWindowKeepsAnchor() {
        let text = String(repeating: "가나다 ", count: 20)
        let scalars = Array(text.unicodeScalars)
        let front = FeedbackCandidates.quoteWindow(
            text, baseStart: 0, baseEnd: scalars.count - 1, anchorStart: 2, anchorEnd: 2
        )
        #expect(front.start == 0)
        #expect(front.end - front.start + 1 <= FeedbackCandidates.quoteMax)
        #expect(scalars[front.end] != " ")
        let back = FeedbackCandidates.quoteWindow(
            text, baseStart: 0, baseEnd: scalars.count - 1, anchorStart: 70, anchorEnd: 70
        )
        #expect((back.start...back.end).contains(70))
        #expect(back.end - back.start + 1 <= FeedbackCandidates.quoteMax)
        #expect(scalars[back.start] != " ")
    }

    @Test func multilineQuoteFlattened() {
        let text = "첫 줄\n둘째 줄로 이어집니다."
        let anchor = Fixtures.index(of: "둘째", in: text, offset: 1)
        let result = Fixtures.result(text, habits: [Fixtures.habit(.midStretch, anchor, anchor)])
        let candidate = FeedbackCandidates.build(from: result).first
        #expect(candidate?.quote == "첫 줄 둘째 줄로 이어집니다.")
        #expect(candidate?.startIdx == 0)
        #expect(candidate?.endIdx == text.unicodeScalars.count - 1)
    }

    @Test func invalidPositionsYieldNone() {
        let count = text.unicodeScalars.count
        let result = Fixtures.result(
            pauses: [Fixtures.pause(8, 900)], phrases: [Fixtures.phrase(0, count + 5, .fast, ratio: 1.5)]
        )
        #expect(FeedbackCandidates.build(from: result).isEmpty)
        #expect(FeedbackComposer.compose(result: result, draft: nil).items.isEmpty)
    }
}
