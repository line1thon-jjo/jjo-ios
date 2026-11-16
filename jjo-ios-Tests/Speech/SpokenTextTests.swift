//
//  SpokenTextTests.swift
//  jjo-ios-Tests
//
//  Created by dohyeoplim on 11/16/26.
//

import Testing
@testable import jjo_ios

struct SpokenTextTests {
    private func build(_ script: String, _ words: [WordTiming]) -> SpokenText {
        SpokenTextBuilder.build(
            script: script,
            units: ScriptText.parse(script),
            words: words.map(TimedWord.init),
            config: .default
        )
    }

    @Test func adoptsLongReplacement() {
        let spoken = build("발표하실 수 있을 것입니다.", [
            WordTiming(text: "발표하실", start: 0.0, end: 0.6, prob: 0.9),
            WordTiming(text: "수", start: 0.6, end: 0.8, prob: 0.9),
            WordTiming(text: "있도록", start: 0.8, end: 1.2, prob: 0.8),
            WordTiming(text: "노력하겠습니다.", start: 1.2, end: 2.2, prob: 0.75),
        ])
        #expect(spoken.text.contains("있도록 노력하겠습니다"))
        #expect(spoken.differences.count == 1)
        #expect(spoken.differences.first?.scriptText?.contains("것입") == true)
    }

    @Test func keepsMisheardTail() {
        let spoken = build("걷는 동안에는 휴대폰을 잠시 내려놓고 주변을 천천히 둘러보세요.", [
            WordTiming(text: "걷는", start: 0.0, end: 0.5, prob: 0.99),
            WordTiming(text: "동안에는", start: 0.5, end: 1.2, prob: 0.95),
            WordTiming(text: "스마트폰", start: 1.2, end: 1.9, prob: 0.9),
            WordTiming(text: "잠깐", start: 1.9, end: 2.3, prob: 0.9),
            WordTiming(text: "넣어두고", start: 2.3, end: 3.0, prob: 0.9),
            WordTiming(text: "지분을", start: 3.0, end: 3.6, prob: 0.45),
            WordTiming(text: "천천히", start: 3.6, end: 4.2, prob: 0.99),
            WordTiming(text: "둘러보세요", start: 4.2, end: 5.0, prob: 0.97),
        ])
        #expect(spoken.differences.contains { $0.kind == .replaced && $0.spoken.contains("스마트폰") })
    }

    @Test func keepsFaithfulScript() {
        let script = "저는 오늘 발표를 합니다."
        let spoken = build(script, [
            WordTiming(text: "저는", start: 0.0, end: 0.4),
            WordTiming(text: "오늘", start: 0.5, end: 0.9),
            WordTiming(text: "발표를", start: 1.0, end: 1.5),
            WordTiming(text: "합니다", start: 1.6, end: 2.2),
        ])
        #expect(spoken.text == script && spoken.differences.isEmpty && spoken.matchRatio == 1)
    }

    @Test func detectsFillerSounds() {
        #expect(["어음", "음어어", "흠"].allSatisfy(Disfluencies.isFillerSound))
        #expect(!["네", "어렵", ""].contains(where: Disfluencies.isFillerSound))
    }
}
