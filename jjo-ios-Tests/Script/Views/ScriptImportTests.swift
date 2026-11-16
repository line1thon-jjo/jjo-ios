//
//  ScriptImportTests.swift
//  jjo-ios-Tests
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation
import Testing
@testable import jjo_ios

struct ScriptImportTests {
    @Test func readsText() {
        let imported = ScriptImport.make(filename: "대본.txt", content: Data("안녕하세요.\n발표입니다.".utf8))
        #expect(imported == ScriptImport(script: "안녕하세요.\n발표입니다."))
    }

    @Test func truncatesLong() {
        let content = Data([0xEF, 0xBB, 0xBF]) + Data(String(repeating: "가", count: 1600).utf8)
        let imported = ScriptImport.make(filename: "long.txt", content: content)
        #expect(imported.script == String(repeating: "가", count: 1500))
        #expect(imported.message == ScriptMessage.tooLong)
    }

    @Test(arguments: [
        ("memo.pdf", Data("대본".utf8), ScriptMessage.fileTypeUnsupported),
        ("memo.txt", Data(" \n ".utf8), ScriptMessage.fileEmpty),
        ("memo.txt", Data(), ScriptMessage.fileEmpty),
        ("memo.txt", Data([0xFF, 0xFE, 0x00]), ScriptMessage.fileInvalidEncoding),
        ("memo.txt", Data(count: ScriptFileReader.maxFileBytes + 1), ScriptMessage.fileTooLarge)
    ])
    func reportsFailure(filename: String, content: Data, message: String) {
        #expect(ScriptImport.make(filename: filename, content: content) == ScriptImport(message: message))
    }
}
