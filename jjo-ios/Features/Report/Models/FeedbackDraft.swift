//
//  FeedbackDraft.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated struct FeedbackDraft: Equatable, Sendable {
    var headline: String?
    var footer: String?
    var items: [Item] = []
}

nonisolated extension FeedbackDraft {
    nonisolated struct Item: Equatable, Sendable {
        var candidateId: Int?
        var title: String?
        var body: String?
    }

    static func decode(_ raw: String) -> FeedbackDraft? {
        guard let payload = try? JSONDecoder().decode(Payload.self, from: Data(raw.utf8)) else { return nil }
        return FeedbackDraft(
            headline: payload.headline,
            footer: payload.footer,
            items: payload.items.map { Item(candidateId: $0.candidateId.value, title: $0.title, body: $0.body) }
        )
    }
}

private nonisolated extension FeedbackDraft {
    nonisolated struct Payload: Decodable {
        let headline: String
        let footer: String
        let items: [PayloadItem]
    }

    nonisolated struct PayloadItem: Decodable {
        let candidateId: LenientInt
        let title: String
        let body: String

        enum CodingKeys: String, CodingKey {
            case candidateId = "candidate_id"
            case title
            case body
        }
    }

    // 서버(pydantic)는 "1", 1.0, true 도 정수로 받아서 같은 입력을 같은 결과로 읽는다
    nonisolated struct LenientInt: Decodable {
        let value: Int

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let int = try? container.decode(Int.self) {
                value = int
            } else if let bool = try? container.decode(Bool.self) {
                value = bool ? 1 : 0
            } else if let int = Int(try container.decode(String.self).pythonStripped()) {
                value = int
            } else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "candidate_id")
            }
        }
    }
}
