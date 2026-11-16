//
//  RecordMessage.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated enum RecordMessage {
    static let tooShort = "녹음이 너무 짧아요. 조금 더 길게 녹음해 주세요."
    static let reachedLimit = "녹음은 10분까지 할 수 있어 여기서 마쳤어요."
    static let unsupported = "이 기기는 한국어 음성 인식을 지원하지 않아 녹음을 분석할 수 없어요."
}
