//
//  FeedbackComposer.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated enum FeedbackComposer {
    static let maxItems = 3

    static func compose(result: AnalysisResult, draft: FeedbackDraft?, model: String? = nil) -> StoredFeedback {
        compose(candidates: FeedbackCandidates.build(from: result), draft: draft, model: model)
    }

    static func compose(
        candidates: [FeedbackCandidate], draft: FeedbackDraft?, model: String? = nil
    ) -> StoredFeedback {
        guard let draft, !candidates.isEmpty else { return ruleFeedback(candidates) }
        return merge(draft, candidates: candidates, model: model)
    }

    static func ruleFeedback(_ candidates: [FeedbackCandidate]) -> StoredFeedback {
        let chosen = FeedbackRules.selection(candidates, limit: maxItems)
        let items = zip(chosen, FeedbackRules.texts(for: chosen)).enumerated().map { offset, pair in
            item(rank: offset + 1, candidate: pair.0, title: pair.1.title, body: pair.1.body)
        }
        return StoredFeedback(source: .rule, summary: FeedbackRules.summary(for: chosen), items: items)
    }

    static func load(_ stored: StoredFeedback?, result: AnalysisResult) -> StoredFeedback {
        guard let stored, stored.version == StoredFeedback.currentVersion else {
            return ruleFeedback(FeedbackCandidates.build(from: result))
        }
        return stored
    }
}

private nonisolated extension FeedbackComposer {
    nonisolated struct Pick {
        var candidate: FeedbackCandidate
        var title: String?
        var body: String?
    }

    // 모델 결과에서 쓸 수 있는 부분만 쓰고, 나머지는 규칙 문구로 채운다
    static func merge(_ draft: FeedbackDraft, candidates: [FeedbackCandidate], model: String?) -> StoredFeedback {
        let byId = Dictionary(candidates.map { ($0.id, $0) }, uniquingKeysWith: { _, last in last })
        let need = min(candidates.count, maxItems)
        var replaced = false
        var picked: [Pick] = []
        for draftItem in draft.items {
            guard let candidate = draftItem.candidateId.flatMap({ byId[$0] }),
                  !picked.contains(where: { $0.candidate.id == candidate.id }),
                  picked.count < need
            else {
                replaced = true
                continue
            }
            let title = cleaned(draftItem.title)
            let body = cleaned(draftItem.body)
            picked.append(
                Pick(
                    candidate: candidate,
                    title: fits(title, limit: FeedbackRules.titleMax) ? title : nil,
                    body: fits(body, limit: FeedbackRules.bodyMax) ? body : nil
                )
            )
        }

        // 빠진 후보는 규칙 순서대로 채운다
        if picked.count < need {
            let missing = need - picked.count
            let rest = candidates.filter { candidate in !picked.contains { $0.candidate.id == candidate.id } }
            let fill = candidates.count <= maxItems ? rest : FeedbackRules.selection(rest, limit: missing)
            picked += fill.prefix(missing).map { Pick(candidate: $0) }
        }

        // 규칙 문구는 최종 순서 기준으로 정해야 같은 종류끼리 문구가 겹치지 않는다
        let chosen = picked.map(\.candidate)
        let items = zip(picked, FeedbackRules.texts(for: chosen)).enumerated().map { offset, pair in
            let (pick, rule) = pair
            replaced = replaced || pick.title == nil || pick.body == nil
            return item(
                rank: offset + 1,
                candidate: pick.candidate,
                title: pick.title ?? rule.title,
                body: pick.body ?? rule.body
            )
        }

        // 총평은 길이를 넘어도 그대로 쓴다. 비었거나 금지어가 든 줄만 규칙 문구로 바꾼다
        var summary = FeedbackSummary(headline: cleaned(draft.headline), footer: cleaned(draft.footer))
        let ruleSummary = FeedbackRules.summary(for: chosen)
        if !isSummaryValid(summary.headline) {
            summary.headline = ruleSummary.headline
            replaced = true
        }
        if !isSummaryValid(summary.footer) {
            summary.footer = ruleSummary.footer
            replaced = true
        }

        return StoredFeedback(source: replaced ? .mixed : .model, model: model, summary: summary, items: items)
    }

    static func item(rank: Int, candidate: FeedbackCandidate, title: String, body: String) -> FeedbackItem {
        FeedbackItem(
            rank: rank,
            title: title,
            quote: candidate.quote,
            body: body,
            startMs: candidate.startMs,
            endMs: candidate.endMs,
            startIdx: candidate.startIdx,
            endIdx: candidate.endIdx,
            kind: candidate.kind
        )
    }

    static func cleaned(_ text: String?) -> String {
        (text ?? "").pythonSplit().joined(separator: " ")
    }

    static func fits(_ text: String, limit: Int) -> Bool {
        let scalars = text.unicodeScalars
        return !scalars.isEmpty && scalars.count <= limit && !scalars.contains("{") && !scalars.contains("}")
    }

    static func isSummaryValid(_ text: String) -> Bool {
        !text.isEmpty && !text.unicodeScalars.contains("{")
            && !FeedbackRules.summaryBanned.contains { text.containsScalars(of: $0) }
    }
}
