//
//  FeedbackComposerTests.swift
//  jjo-ios-Tests
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation
import Testing
@testable import jjo_ios

struct FeedbackComposerTests {
    typealias Fixtures = ReportFixtures

    private let model = "on-device"

    private func item(_ id: Int?, _ title: String? = "늘이지 않기", _ body: String? = "늘였어요.") -> FeedbackDraft.Item {
        FeedbackDraft.Item(candidateId: id, title: title, body: body)
    }

    private func draft(
        _ items: [FeedbackDraft.Item], headline: String? = "호흡이 안정적이었어요.", footer: String? = "늘이는 부분만 다듬어 보세요."
    ) -> FeedbackDraft {
        FeedbackDraft(headline: headline, footer: footer, items: items)
    }

    private func compose(_ draft: FeedbackDraft?, result: AnalysisResult = Fixtures.richResult()) -> StoredFeedback {
        FeedbackComposer.compose(result: result, draft: draft, model: model)
    }

    @Test func emptyUsesPraise() {
        let stored = compose(draft([item(1)]), result: Fixtures.result())
        #expect(stored.items.isEmpty && stored.source == .rule && stored.model == nil)
        #expect(stored.summary == FeedbackRules.noIssueSummary)
    }

    @Test func noDraftUsesRules() {
        let stored = compose(nil)
        #expect(stored.source == .rule && stored.model == nil)
        #expect(stored.items.count == 3)
        #expect(Set(stored.items.map(\.kind)).count == 3)
        #expect(stored.items.map(\.rank) == [1, 2, 3])
    }

    @Test func validDraftKeepsOrder() {
        let stored = compose(draft([
            item(4, "쉼 줄이기", "여기서 0.9초 쉬었어요. 조금 짧게 쉬어 보세요."),
            item(1, "늘이지 않기", "글자를 길게 늘였어요."),
            item(3, "천천히 말하기", "이 구절이 빨랐어요.")
        ]))
        #expect(stored.source == .model && stored.model == model)
        #expect(stored.items.map(\.rank) == [1, 2, 3])
        #expect(stored.items.map(\.kind) == [.pause, .midStretch, .pace])
        #expect(stored.summary.headline == "호흡이 안정적이었어요.")
        let first = stored.items[0]
        #expect(first.quote == Fixtures.slice(Fixtures.text, first.startIdx, first.endIdx))
    }

    @Test func invalidPartsReplaced() {
        let longTitle = String(repeating: "가", count: FeedbackRules.titleMax + 1)
        let stored = compose(draft([
            item(99, "없는 후보", "x"), item(1, longTitle, "글자를 길게 늘였어요."), item(1, "중복", "중복")
        ], headline: " "))
        #expect(stored.source == .mixed && stored.items.count == 3)
        let candidates = FeedbackCandidates.build(from: Fixtures.richResult())
        #expect(stored.items[0].title == FeedbackRules.text(for: candidates[0]).title)
        #expect(stored.items[0].body == "글자를 길게 늘였어요.")
        #expect(Set(stored.items.map { [$0.startIdx, $0.endIdx] }).count == 3)
        #expect(stored.summary.headline == "전체적으로 무난했어요.")
    }

    @Test func bannedLineReplaced() {
        let stored = compose(draft([item(1)], headline: "전체적으로 차분하게 잘하셨어요", footer: "늘이는 말만 줄여 보세요."))
        #expect(stored.summary.headline == "전체적으로 무난했어요.")
        #expect(stored.summary.footer == "늘이는 말만 줄여 보세요.")
        #expect(stored.source == .mixed)
    }

    @Test func longSummaryKept() {
        let headline = String(repeating: "가", count: FeedbackRules.headlineMax + 4)
        let footer = String(repeating: "나", count: FeedbackRules.footerMax + 2)
        let stored = compose(draft([item(1)], headline: headline, footer: footer))
        #expect(stored.summary == FeedbackSummary(headline: headline, footer: footer))
    }

    @Test func fewCandidatesAllKept() {
        let anchor = Fixtures.index(of: "시작하겠습니다", offset: 2)
        let result = Fixtures.result(
            pauses: [Fixtures.pause(Fixtures.index(of: "여러분", offset: 2), 900)],
            habits: [Fixtures.habit(.midStretch, anchor, anchor)],
            stretched: [anchor: 2.5]
        )
        let stored = compose(draft([item(2, "쉼 줄이기", "쉬는 시간이 길었어요.")]), result: result)
        #expect(stored.items.map(\.kind) == [.pause, .midStretch])
        #expect(stored.source == .mixed)
    }

    @Test func placeholdersRejected() {
        let stored = compose(draft([
            item(1, "{word} 줄이기", "‘{word}’ 뒤에서 쉬었어요."), item(3, "닫는 괄호}", "괜찮은 설명이에요."),
            item(4, "괜찮은 제목", "괜찮은 설명이에요.")
        ]))
        let rules = FeedbackRules.texts(for: [1, 3, 4].compactMap { id in
            FeedbackCandidates.build(from: Fixtures.richResult()).first { $0.id == id }
        })
        #expect(stored.items[0].title == rules[0].title && stored.items[0].body == rules[0].body)
        #expect(stored.items[1].title == rules[1].title && stored.items[1].body == "괜찮은 설명이에요.")
        #expect(stored.items[2].title == "괜찮은 제목")
        #expect(stored.source == .mixed)
    }

    @Test func lengthBoundaries() {
        let title = String(repeating: "가", count: FeedbackRules.titleMax)
        let body = String(repeating: "나", count: FeedbackRules.bodyMax)
        let exact = compose(draft([item(1, title, body), item(3), item(4)]))
        #expect(exact.source == .model)
        #expect(exact.items[0].title == title && exact.items[0].body == body)
        let over = compose(draft([item(1, title, body + "나"), item(3), item(4)]))
        #expect(over.source == .mixed)
        #expect(over.items[0].title == title && over.items[0].body != body + "나")
    }

    @Test func whitespaceCollapsed() {
        let stored = compose(draft([
            item(1, "  여러\n줄 \t제목  ", "첫 줄이에요.\n\n둘째 줄이에요. "), item(3), item(4)
        ], headline: "  총평\n입니다  "))
        #expect(stored.items[0].title == "여러 줄 제목")
        #expect(stored.items[0].body == "첫 줄이에요. 둘째 줄이에요.")
        #expect(stored.summary.headline == "총평 입니다")
        #expect(stored.source == .model)
    }

    @Test func extraItemsDropped() {
        let stored = compose(draft([item(1), item(2), item(3), item(4)]))
        #expect(stored.items.count == FeedbackComposer.maxItems)
        #expect(stored.items.map(\.startIdx).count == 3)
        #expect(stored.source == .mixed)
    }

    @Test func partialDraftFilled() {
        let stored = compose(FeedbackDraft(items: [item(4, "쉼 줄이기", nil), item(nil), item(1, nil, "늘였어요.")]))
        let candidates = FeedbackCandidates.build(from: Fixtures.richResult())
        #expect(stored.items.map(\.kind) == [.pause, .midStretch, .midStretch])
        #expect(stored.items[0].title == "쉼 줄이기")
        #expect(stored.items[0].body == FeedbackRules.text(for: candidates[3]).body)
        #expect(stored.items[1].title == FeedbackRules.text(for: candidates[0]).title)
        #expect(stored.items[1].body == "늘였어요.")
        #expect(stored.summary == FeedbackSummary(headline: "전체적으로 무난했어요.", footer: "쉼 부분만 다듬어 보세요."))
        #expect(stored.source == .mixed && stored.model == model)
    }

    @Test(arguments: ["not json", "{}", #"{"headline": 1}"#, #"{"headline": "a", "items": []}"#, "[1]", ""])
    func malformedDecodesNil(raw: String) {
        #expect(FeedbackDraft.decode(raw) == nil)
        #expect(compose(FeedbackDraft.decode(raw)).source == .rule)
    }

    @Test func decodesServerShape() {
        let raw = """
        {"headline": "좋았어요.", "footer": "다듬어요.", "note": 1, "items": [
        {"candidate_id": 2, "title": "제목", "body": "설명"}, {"candidate_id": "3", "title": "t", "body": "b"}]}
        """
        #expect(FeedbackDraft.decode(raw) == FeedbackDraft(
            headline: "좋았어요.", footer: "다듬어요.",
            items: [item(2, "제목", "설명"), item(3, "t", "b")]
        ))
    }

    @Test func loadFallsBack() {
        let result = Fixtures.richResult()
        var outdated = compose(draft([item(1)]))
        outdated.version = 99
        for stored in [nil, outdated] {
            let loaded = FeedbackComposer.load(stored, result: result)
            #expect(loaded.source == .rule && loaded.items.count == 3)
        }
        let saved = compose(draft([item(1)]))
        #expect(FeedbackComposer.load(saved, result: result).items.first?.title == "늘이지 않기")
    }
}
