//
//  ScriptValidator.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated enum ScriptValidationError: Error, Equatable, Sendable {
    case empty
    case tooLong
    case blank
}

nonisolated enum ScriptValidator {
    static let maxLength = 1500

    static func error(in script: String) -> ScriptValidationError? {
        let length = script.scalarCount
        if length < 1 { return .empty }
        if length > maxLength { return .tooLong }
        if script.pythonStripped().isEmpty { return .blank }
        return nil
    }

    // 분석의 글자 위치 기준이 원문이라 앞뒤 공백을 지우지 않고 그대로 돌려준다
    static func validated(_ script: String) throws(ScriptValidationError) -> String {
        if let error = error(in: script) { throw error }
        return script
    }
}
