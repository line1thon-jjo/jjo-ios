//
//  FeedbackWriter.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation
import FoundationModels

@Generable
nonisolated struct FeedbackItemDraft: Sendable {
    @Guide(description: "무엇을 연습할지 알려 주는 20자 이내의 짧은 구절")
    var title: String

    @Guide(description: "어떤 일이 있었는지와 연습 방법을 '~요'로 끝나는 해요체 1~2문장, 90자 이내")
    var body: String
}

nonisolated enum FeedbackWriter {
    static let modelName = "apple-on-device"

    @concurrent
    static func write(for result: AnalysisResult) async -> StoredFeedback {
        let candidates = FeedbackCandidates.build(from: result)
        guard !candidates.isEmpty, OnDeviceModel.isAvailable else {
            return FeedbackComposer.compose(candidates: candidates, draft: nil)
        }

        var items: [FeedbackDraft.Item] = []
        for candidate in FeedbackRules.selection(candidates, limit: FeedbackComposer.maxItems) {
            let generated = await OnDeviceModel.generate(
                FeedbackItemDraft.self,
                instructions: FeedbackPrompt.slimSystemInstruction,
                prompt: FeedbackPrompt.slimUserMessage(candidate: candidate)
            )
            let accepted = generated.flatMap { isPolite($0.body) ? $0 : nil }
            items.append(
                FeedbackDraft.Item(candidateId: candidate.id, title: accepted?.title, body: accepted?.body)
            )
        }
        let draft = FeedbackDraft(headline: nil, footer: nil, items: items)
        return FeedbackComposer.compose(candidates: candidates, draft: draft, model: modelName)
    }

    // 온디바이스 모델이 반말로 쓰는 경우가 있어, 모든 문장이 해요체로 끝날 때만 받아들인다
    static func isPolite(_ text: String) -> Bool {
        let sentences = text
            .split(whereSeparator: { ".!?".contains($0) })
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return !sentences.isEmpty && sentences.allSatisfy { $0.hasSuffix("요") || $0.hasSuffix("죠") }
    }
}
