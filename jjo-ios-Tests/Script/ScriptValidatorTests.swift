//
//  ScriptValidatorTests.swift
//  jjo-ios-Tests
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation
import Testing
@testable import jjo_ios

struct ScriptValidatorTests {
    @Test(arguments: ["안녕하세요. 발표를 시작합니다.", "가", String(repeating: "가", count: 1500), " \r\n 대본\t\n "])
    func acceptsScript(script: String) throws {
        #expect(try ScriptValidator.validated(script) == script)
    }

    @Test(arguments: [" ", "\t", "\n", " \t\r\n  ", "\u{3000}"])
    func rejectsBlank(script: String) {
        #expect(ScriptValidator.error(in: script) == .blank)
    }

    @Test func rejectsEmpty() {
        #expect(ScriptValidator.error(in: "") == .empty)
        #expect(throws: ScriptValidationError.empty) { try ScriptValidator.validated("") }
    }

    @Test(arguments: [String(repeating: "가", count: 1501), String(repeating: "가", count: 1500) + " "])
    func rejectsTooLong(script: String) {
        #expect(ScriptValidator.error(in: script) == .tooLong)
    }

    @Test func countsCodePoints() {
        #expect(ScriptValidator.error(in: String(repeating: "😀", count: 1500)) == nil)
        #expect(ScriptValidator.error(in: String(repeating: "\r\n", count: 750) + "가") == .tooLong)
    }
}
