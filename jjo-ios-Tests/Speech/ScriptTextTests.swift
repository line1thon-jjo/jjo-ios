//
//  ScriptTextTests.swift
//  jjo-ios-Tests
//
//  Created by dohyeoplim on 11/16/26.
//

import Testing
@testable import jjo_ios

struct ScriptTextTests {
    private func sentenceEnds(_ script: String) -> [String] {
        ScriptText.parse(script).filter(\.isSentenceEnd).map { String($0.char) }
    }

    @Test func parsesBoundaries() {
        let script = "안녕, 반가워요. 오늘 3.5점이에요?\n네"
        let units = ScriptText.parse(script)
        #expect(units.map(\.char).text == "안녕반가워요오늘35점이에요네")
        #expect(units[1].boundaryAfter == .comma)
        #expect(Array(script.unicodeScalars)[units[1].idx] == "녕")
        #expect(units.first { $0.isSentenceEnd }?.char == "요")
        let questions = units.filter(\.isQuestionEnd)
        #expect(questions.count == 1 && questions[0].char == "요")
        #expect(units.last?.isSentenceEnd == true)
    }

    @Test func lineBreaksEndSentences() {
        #expect(sentenceEnds("오늘은 발표를 합니다\n내일은 쉽니다") == ["다", "다"])
    }

    @Test func infersSentenceEnds() {
        let units = ScriptText.parse("오늘은 발표를 시작하겠습니다 이번 주제는 결제 문화입니다 감사합니다")
        let ends = units.filter(\.isSentenceEnd)
        #expect(ends.map(\.char).text == "다다다")
        #expect(ends.allSatisfy { $0.strength == 3 })
    }

    @Test func infersClauseBreaks() {
        let units = ScriptText.parse("비가 오는데 우산을 챙겼어요 이해가 되셨나요")
        let clauses = units.filter { $0.boundaryAfter == .comma }
        #expect(clauses.map(\.char).text == "데")
        #expect(clauses.first?.strength == 2)
        let ends = units.filter(\.isSentenceEnd)
        #expect(ends.map(\.char).text == "요요")
        #expect(ends.map(\.isQuestionEnd) == [false, true])
        #expect(ends.first?.strength == 3)
    }

    @Test func skipsNounYo() {
        #expect(sentenceEnds("이것이 필요 합니다") == ["다"])
    }

    @Test func punctuationDisablesInference() {
        #expect(sentenceEnds("저는 갑니다 그리고 옵니다. 끝") == ["다", "끝"])
    }

    @Test func indexesCodePoints() {
        let script = "\u{FEFF}안녕😀하세요.\r\n👍🏽 AI 3.5점 ❤️끝"
        let units = ScriptText.parse(script)
        #expect(units.map(\.idx) == [1, 2, 4, 5, 6, 13, 14, 16, 18, 19, 22, 23])
        #expect(units.map(\.char).text == "안녕하세요AI35점\u{FE0F}끝")
        #expect(units.map(\.wordId) == [0, 0, 0, 0, 0, 1, 1, 2, 2, 2, 3, 3])
        #expect(units[4].boundaryAfter == .sentence)
        #expect(units.map(\.sentenceId) == [0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1])
        #expect(units.map(\.isHangul) == [true, true, true, true, true, false, false, false, false, true, false, true])
    }

    @Test func classifiesPythonCharacters() {
        #expect("\u{3000}".unicodeScalars.allSatisfy { $0.isPythonSpace })
        #expect("\u{200B}".unicodeScalars.allSatisfy { !$0.isPythonSpace })
        #expect("²٣7".unicodeScalars.allSatisfy { $0.isPythonDigit })
        #expect("½".unicodeScalars.allSatisfy { !$0.isPythonDigit && $0.isPythonAlnum })
        #expect("²".unicodeScalars.allSatisfy { !$0.isPythonDecimal })
    }
}
