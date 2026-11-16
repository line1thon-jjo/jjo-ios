//
//  TitleWriter.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated enum TitleWriter {
    static let promptScalarLimit = 800

    @concurrent
    static func title(for script: String) async -> String {
        let excerpt = String(String.UnicodeScalarView(script.unicodeScalars.prefix(promptScalarLimit)))
        let generated = await OnDeviceModel.respond(
            instructions: ScriptTitle.systemInstruction,
            prompt: ScriptTitle.userMessage(script: excerpt),
            maximumTokens: 80
        )
        return ScriptTitle.resolve(generated: generated, script: script)
    }
}
