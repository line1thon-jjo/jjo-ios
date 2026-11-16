//
//  FeedbackRules.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated enum FeedbackRules {
    static let headlineMax = 20
    static let footerMax = 30
    static let titleMax = 20
    static let bodyMax = 90
    // 모델은 글자 수를 정확히 못 세서 총평은 명세보다 짧게 시키고, 조금 넘어도 그대로 쓴다
    static let headlineTarget = 15
    static let footerTarget = 24
    static let variantCount = 3
    static let noIssueSummary = FeedbackSummary(headline: "안정적으로 잘 말했어요.", footer: "지금처럼 꾸준히 연습해 보세요.")

    nonisolated enum TemplateKey: String, Sendable, CaseIterable {
        case endRise = "END_RISE"
        case endStretch = "END_STRETCH"
        case endFade = "END_FADE"
        case midStretch = "MID_STRETCH"
        case midPause = "MID_PAUSE"
        case longPause = "LONG_PAUSE"
        case noBreak = "NO_BREAK"
        case paceFast = "PACE_FAST"
        case paceSlow = "PACE_SLOW"
        case pause = "PAUSE"
    }

    nonisolated struct Text: Codable, Equatable, Sendable {
        var title: String
        var body: String
    }

    nonisolated struct ConditionalExample: Equatable, Sendable {
        var when: String
        var body: String
    }

    nonisolated struct Examples: Equatable, Sendable {
        var title: [String]
        var body: [String]
        var conditional: [ConditionalExample]
    }

    nonisolated struct FillValues: Codable, Equatable, Sendable {
        var word: String?
        var char: String?
        var spot: String?
        var sec: String?
    }

    static func kindName(_ kind: FeedbackKind) -> String {
        kindNames[kind] ?? ""
    }

    static func advice(for candidate: FeedbackCandidate) -> String {
        advices[templateKey(candidate)] ?? ""
    }

    static func templateKey(_ candidate: FeedbackCandidate) -> TemplateKey {
        switch candidate.kind {
        case .endRise: .endRise
        case .endStretch: .endStretch
        case .endFade: .endFade
        case .midStretch: .midStretch
        case .midPause: .midPause
        case .longPause: .longPause
        case .noBreak: .noBreak
        case .pace: candidate.metrics.speed == .slow ? .paceSlow : .paceFast
        case .pause: .pause
        }
    }

    // 쉼 길이를 화면 표기와 같은 소수 첫째 자리 초로
    static func pauseSec(_ candidate: FeedbackCandidate) -> String? {
        guard let durationMs = candidate.metrics.durationMs, durationMs != 0 else { return nil }
        return String(format: "%.1f", Double(durationMs) / 1000)
    }

    static func fillValues(_ candidate: FeedbackCandidate) -> FillValues {
        let word = nonEmpty(candidate.kind.isGap ? candidate.focus.wordBefore : candidate.focus.word)
        let char = nonEmpty(candidate.focus.char)
        let spot = char.map { char in
            if let word, !word.hasSameScalars(as: char) {
                "‘\(word)’의 ‘\(char)’"
            } else {
                "‘\(char)’"
            }
        }
        return FillValues(word: word, char: char, spot: spot, sec: pauseSec(candidate))
    }

    static func examples(_ candidate: FeedbackCandidate) -> Examples {
        let key = templateKey(candidate)
        let texts = templates[key] ?? []
        return Examples(
            title: texts.map(\.title), body: texts.map(\.body), conditional: conditionalExamples[key] ?? []
        )
    }

    static func text(for candidate: FeedbackCandidate, variant: Int = 0) -> Text {
        let key = templateKey(candidate)
        let index = ((variant % variantCount) + variantCount) % variantCount
        guard let template = templates[key]?[index], let fallback = generic[key]?[index] else {
            return Text(title: "", body: "")
        }
        guard let body = filled(template.body, with: fillValues(candidate)), body.scalarCount <= bodyMax else {
            return fallback
        }
        return Text(title: template.title, body: body)
    }

    // 같은 종류가 겹치면 나온 순서대로 다른 문구를 쓴다
    static func texts(for candidates: [FeedbackCandidate]) -> [Text] {
        var seen: [TemplateKey: Int] = [:]
        return candidates.map { candidate in
            let key = templateKey(candidate)
            defer { seen[key, default: 0] += 1 }
            return text(for: candidate, variant: seen[key, default: 0])
        }
    }

    static func summary(for chosen: [FeedbackCandidate]) -> FeedbackSummary {
        guard let first = chosen.first else { return noIssueSummary }
        return FeedbackSummary(headline: "전체적으로 무난했어요.", footer: "\(kindName(first.kind)) 부분만 다듬어 보세요.")
    }

    // 후보가 limit 개 이하면 전부, 넘으면 종류가 겹치지 않게 앞에서부터 고르고 모자라면 순서대로 채운다
    static func selection(_ candidates: [FeedbackCandidate], limit: Int = 3) -> [FeedbackCandidate] {
        guard candidates.count > limit else { return candidates }
        var chosen: [FeedbackCandidate] = []
        var kinds: Set<FeedbackKind> = []
        for candidate in candidates where chosen.count < limit && !kinds.contains(candidate.kind) {
            chosen.append(candidate)
            kinds.insert(candidate.kind)
        }
        for candidate in candidates where chosen.count < limit && !chosen.contains(candidate) {
            chosen.append(candidate)
        }
        return chosen.stableSorted(by: \.id)
    }
}

private nonisolated extension FeedbackRules {
    static func nonEmpty(_ text: String?) -> String? {
        text.flatMap { $0.isEmpty ? nil : $0 }
    }

    static func filled(_ template: String, with values: FillValues) -> String? {
        var out = String.UnicodeScalarView()
        var name: String.UnicodeScalarView?
        for scalar in template.unicodeScalars {
            if scalar == "{" {
                name = String.UnicodeScalarView()
            } else if scalar == "}", let placeholder = name {
                guard let value = value(named: String(placeholder), in: values) else { return nil }
                out.append(contentsOf: value.unicodeScalars)
                name = nil
            } else if name != nil {
                name?.append(scalar)
            } else {
                out.append(scalar)
            }
        }
        return String(out)
    }

    static func value(named name: String, in values: FillValues) -> String? {
        switch name {
        case "word": values.word
        case "char": values.char
        case "spot": values.spot
        case "sec": values.sec
        default: nil
        }
    }
}
