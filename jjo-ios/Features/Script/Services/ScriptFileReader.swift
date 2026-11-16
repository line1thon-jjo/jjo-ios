//
//  ScriptFileReader.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated enum ScriptFileError: Error, Equatable, Sendable {
    case typeUnsupported
    case tooLarge
    case invalidEncoding
    case textEmpty
    case invalidScript(ScriptValidationError)
}

nonisolated enum ScriptFileReader {
    static let maxFileBytes = 1024 * 1024
    private static let byteOrderMark: [UInt8] = [0xEF, 0xBB, 0xBF]

    static func extractScript(filename: String?, content: Data) throws(ScriptFileError) -> String {
        guard let filename, fileSuffix(filename).lowercased() == ".txt" else { throw .typeUnsupported }
        guard content.count <= maxFileBytes else { throw .tooLarge }
        let bytes = content.starts(with: byteOrderMark) ? content.dropFirst(byteOrderMark.count) : content
        guard let script = String(validating: bytes, as: UTF8.self) else { throw .invalidEncoding }
        guard !script.pythonStripped().isEmpty else { throw .textEmpty }
        if let error = ScriptValidator.error(in: script) { throw .invalidScript(error) }
        return script
    }

    static func fileSuffix(_ filename: String) -> String {
        guard let name = filename.split(separator: "/").last(where: { $0 != "." }) else { return "" }
        let scalars = Array(name.unicodeScalars)
        guard let dot = scalars.lastIndex(of: "."), dot > 0, dot < scalars.count - 1 else { return "" }
        return String(scalars: scalars[dot...])
    }
}
