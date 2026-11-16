//
//  ReportFailure.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated struct ReportFailure: Codable, Equatable, Sendable {
    var code: AnalysisErrorCode
}

nonisolated extension ReportFailure {
    init(reason: String?) {
        code = reason.flatMap(AnalysisErrorCode.init(rawValue:)) ?? .internal
    }
}
