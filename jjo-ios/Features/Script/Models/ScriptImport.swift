//
//  ScriptImport.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated struct ScriptImport: Equatable, Sendable {
    var script: String?
    var message: String?

    static func make(filename: String, content: Data) -> ScriptImport {
        do {
            return ScriptImport(script: try ScriptFileReader.extractScript(filename: filename, content: content))
        } catch .invalidScript(.tooLong) {
            // 웹은 긴 파일을 거절하지 않고 앞 1,500자만 남긴 뒤 알려 준다
            let scalars = String(decoding: content, as: UTF8.self).unicodeScalars
            let text = String(scalars: scalars.first == "\u{FEFF}" ? scalars.dropFirst() : scalars[...])
            return ScriptImport(script: text.scalarPrefix(ScriptValidator.maxLength), message: ScriptMessage.tooLong)
        } catch {
            return ScriptImport(message: ScriptMessage.message(for: error))
        }
    }

    @concurrent
    static func load(from url: URL) async -> ScriptImport {
        let isScoped = url.startAccessingSecurityScopedResource()
        defer {
            if isScoped { url.stopAccessingSecurityScopedResource() }
        }

        if let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize, size > ScriptFileReader.maxFileBytes {
            return ScriptImport(message: ScriptMessage.fileTooLarge)
        }
        guard let content = try? Data(contentsOf: url) else {
            return ScriptImport(message: ScriptMessage.unreadable)
        }
        return make(filename: url.lastPathComponent, content: content)
    }
}
