//
//  ScriptFileReaderTests.swift
//  jjo-ios-Tests
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation
import Testing
@testable import jjo_ios

struct ScriptFileReaderTests {
    private nonisolated static let byteOrderMark = Data([0xEF, 0xBB, 0xBF])

    @Test(arguments: ["가", String(repeating: "가", count: 1500), " \r\n 대본\t\n "], [Data(), byteOrderMark])
    func preservesText(script: String, prefix: Data) throws {
        let content = prefix + Data(script.utf8)
        #expect(try ScriptFileReader.extractScript(filename: "script.TXT", content: content) == script)
    }

    @Test(arguments: [nil, "script.pdf", "script.txt.pdf", ".txt", "txt"])
    func rejectsFileType(filename: String?) {
        #expect(throws: ScriptFileError.typeUnsupported) {
            try ScriptFileReader.extractScript(filename: filename, content: Data("text".utf8))
        }
    }

    @Test func rejectsLargeFile() {
        let content = Data(repeating: 0x61, count: ScriptFileReader.maxFileBytes + 1)
        #expect(throws: ScriptFileError.tooLarge) {
            try ScriptFileReader.extractScript(filename: "script.txt", content: content)
        }
    }

    @Test(arguments: [Data([0xFF, 0xFE]), Data([0xE3, 0x81])])
    func rejectsEncoding(content: Data) {
        #expect(throws: ScriptFileError.invalidEncoding) {
            try ScriptFileReader.extractScript(filename: "script.txt", content: content)
        }
    }

    @Test(arguments: [Data(), byteOrderMark, Data(" \r\n\t".utf8)])
    func rejectsEmptyText(content: Data) {
        #expect(throws: ScriptFileError.textEmpty) {
            try ScriptFileReader.extractScript(filename: "script.txt", content: content)
        }
    }

    @Test(arguments: [
        Data(String(repeating: "가", count: 1501).utf8), Data(repeating: 0x61, count: ScriptFileReader.maxFileBytes)
    ])
    func appliesScriptLimit(content: Data) {
        #expect(throws: ScriptFileError.invalidScript(.tooLong)) {
            try ScriptFileReader.extractScript(filename: "script.txt", content: content)
        }
    }

    @Test func stripsOneMark() throws {
        let content = Self.byteOrderMark + Self.byteOrderMark + Data("대본".utf8)
        #expect(try ScriptFileReader.extractScript(filename: "a.txt", content: content) == "\u{FEFF}대본")
    }
}
