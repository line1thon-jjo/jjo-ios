//
//  ScriptUnit.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated enum ScriptBoundary: Int, Sendable {
    case none
    case word
    case comma
    case line
    case sentence

    var strength: Int {
        switch self {
        case .none: 0
        case .word: 1
        case .comma, .line: 2
        case .sentence: 3
        }
    }

    var pauseBoundary: PauseBoundary {
        switch self {
        case .none: .wordInternal
        case .word: .word
        case .comma: .comma
        case .line: .line
        case .sentence: .sentence
        }
    }
}

nonisolated struct ScriptUnit: Equatable, Sendable {
    let idx: Int
    let char: Unicode.Scalar
    let isHangul: Bool
    let wordId: Int
    let boundaryAfter: ScriptBoundary
    let strength: Int
    let sentenceId: Int
    let isSentenceEnd: Bool
    let isQuestionEnd: Bool

    var hasBatchim: Bool { char.hasBatchim }
}
