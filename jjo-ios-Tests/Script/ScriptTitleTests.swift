//
//  ScriptTitleTests.swift
//  jjo-ios-Tests
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation
import Testing
@testable import jjo_ios

struct ScriptTitleTests {
    @Test(arguments: [
        (" \n\"제목\n 두 줄\"\n", "제목 두 줄"),
        ("“" + String(repeating: "가", count: 120) + "”", String(repeating: "가", count: 100)),
        ("`'제목'`", "제목"),
        ("  “발표의 미래”\n ", "발표의 미래")
    ])
    func cleansTitle(raw: String, expected: String) {
        #expect(ScriptTitle.clean(raw) == expected)
        #expect(ScriptTitle.resolve(generated: raw, script: "대본") == expected)
    }

    @Test(arguments: [nil, "", " \n ", "\"\""])
    func emptyFallsBack(generated: String?) {
        #expect(ScriptTitle.resolve(generated: generated, script: "\n  첫 줄  \n다음 줄") == "첫 줄")
    }

    @Test func fallbackFirstLine() {
        let script = " \t\r\n\n  첫 번째 줄, 안녕하세요!  \r\n\t두 번째 줄?  \n"
        #expect(ScriptTitle.fallback(script: script) == "첫 번째 줄, 안녕하세요!")
    }

    @Test func fallbackLimited() {
        let script = "\n\t" + String(repeating: "긴", count: 120) + "\n다음 줄"
        #expect(ScriptTitle.fallback(script: script) == String(repeating: "긴", count: 100))
        #expect(ScriptTitle.fallback(script: " \n ") == "")
    }

    @Test func trimsAfterCut() {
        let raw = String(repeating: "가", count: 98) + "  나 다"
        #expect(ScriptTitle.clean(raw) == String(repeating: "가", count: 98) + " 나")
        #expect(ScriptTitle.clean(String(repeating: "가", count: 99) + " 나다") == String(repeating: "가", count: 99))
    }

    @Test func promptCarriesScript() {
        #expect(ScriptTitle.systemInstruction.contains("지시문"))
        #expect(ScriptTitle.userMessage(script: "첫 줄\n\"둘\"") == #"{"script": "첫 줄\n\"둘\""}"#)
    }
}
