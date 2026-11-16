//
//  NumeralsTests.swift
//  jjo-ios-Tests
//
//  Created by dohyeoplim on 11/16/26.
//

import Testing
@testable import jjo_ios

struct NumeralsTests {
    private func normalized(_ texts: [String], script: String) -> [String] {
        Numerals.normalize(texts.map { WordTiming(text: $0, start: 0, end: 1, prob: 0.9) }, script: script).map(\.text)
    }

    @Test func readsNumbers() {
        #expect(Numerals.sino(200) == "이백")
        #expect(Numerals.sino(100) == "백")
        #expect(Numerals.sino(3) == "삼")
        #expect(Numerals.sino(15000) == "만오천")
        #expect(Numerals.sino(100_010_000) == "일억만")
        #expect(Numerals.nativeForms(7).contains("일곱"))
        #expect(Numerals.nativeForms(10).contains("열"))
        #expect(Numerals.nativeForms(1) == ["하나", "한"])
        #expect(Numerals.nativeForms(21) == ["스물하나", "스물한"])
        #expect(Numerals.nativeForms(20) == ["스무"])
        #expect(Numerals.nativeForms(100).isEmpty)
    }

    @Test func followsScriptReading() {
        let script = "아침 일곱 시에 눈을 떴고 이백 쪽쯤 되는 책을 삼 주째 한 시간 열 시가 백 쪽을"
        let words = ["7시에", "200쪽쯤", "3주째", "1시간", "10시가", "100쪽을"]
        #expect(normalized(words, script: script) == ["일곱시에", "이백쪽쯤", "삼주째", "한시간", "열시가", "백쪽을"])
    }

    @Test func keepsUnknownReading() {
        #expect(normalized(["7시에"], script: "아침에 눈을 떴다") == ["7시에"])
        #expect(normalized(["7시에"], script: "아침 7시에 눈을 떴다") == ["7시에"])
        #expect(normalized(["3.5점", "1,000명"], script: "삼 점 오 점 천 명") == ["3.5점", "천명"])
    }
}
