//
//  ScriptMessage.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated enum ScriptMessage {
    static let description = "3~5분 정도의 짧은 대본이 좋아요."
    static let placeholder = "발표 대본을 입력해주세요."
    static let empty = "발표 대본을 입력해주세요."
    static let tooLong = "대본은 최대 1,500자까지 입력할 수 있습니다."
    static let unreadable = "파일을 읽을 수 없습니다."
    static let fileTooLarge = "대본 파일은 1MB까지 올릴 수 있어요."
    static let fileTypeUnsupported = "TXT 파일만 올릴 수 있어요."
    static let fileInvalidEncoding = "UTF-8로 저장한 파일만 읽을 수 있어요."
    static let fileEmpty = "대본 파일이 비어 있어요."

    static func message(for error: ScriptFileError) -> String {
        switch error {
        case .typeUnsupported: fileTypeUnsupported
        case .tooLarge: fileTooLarge
        case .invalidEncoding: fileInvalidEncoding
        case .textEmpty, .invalidScript(.empty), .invalidScript(.blank): fileEmpty
        case .invalidScript(.tooLong): tooLong
        }
    }
}
