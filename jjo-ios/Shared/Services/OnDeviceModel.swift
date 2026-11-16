//
//  OnDeviceModel.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation
import FoundationModels

nonisolated enum OnDeviceModel {
    static var isAvailable: Bool {
        guard case .available = SystemLanguageModel.default.availability else { return false }
        return true
    }

    @concurrent
    static func respond(
        instructions: String,
        prompt: String,
        temperature: Double = 0.3,
        maximumTokens: Int = 200
    ) async -> String? {
        guard isAvailable else { return nil }
        let session = LanguageModelSession(instructions: instructions)
        let options = GenerationOptions(temperature: temperature, maximumResponseTokens: maximumTokens)
        return try? await session.respond(to: prompt, options: options).content
    }

    @concurrent
    static func generate<Content: Generable>(
        _ type: Content.Type,
        instructions: String,
        prompt: String,
        temperature: Double = 0.4
    ) async -> Content? {
        guard isAvailable else { return nil }
        let session = LanguageModelSession(instructions: instructions)
        let options = GenerationOptions(temperature: temperature)
        return try? await session.respond(to: prompt, generating: type, options: options).content
    }
}
