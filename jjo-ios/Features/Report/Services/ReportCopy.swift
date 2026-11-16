//
//  ReportCopy.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated enum ReportCopy {
    static let fallbackError = "문제가 생겼어요. 잠시 후 다시 시도해 주세요."
    static let recordingNotFound = "녹음을 찾을 수 없어요."

    static func habitName(_ type: HabitType) -> String {
        switch type {
        case .endRise: "끝 올림"
        case .endStretch: "끝 끌기"
        case .endFade: "끝 흐림"
        case .midStretch: "중간 늘임"
        case .midPause: "중간 쉼"
        case .longPause: "긴 쉼"
        case .noBreak: "이어 말하기"
        }
    }

    static func statusLabel(_ status: ReportStatus) -> String {
        switch status {
        case .pending, .analyzing: "분석 중"
        case .completed: "완료"
        case .failed: "실패"
        }
    }

    static func warning(_ warning: ReportWarning) -> String {
        switch warning {
        case .pitchUnavailable: "높낮이를 정확히 잡지 못했어요. 글자 높낮이 표시가 없거나 적을 수 있어요."
        case .partialAlignment: "대본과 맞춰 보지 못한 부분이 있어요. 일부 구절만 분석했어요."
        case .scriptDeviation: "대본과 다르게 말한 부분이 많아요. 결과가 정확하지 않을 수 있어요."
        }
    }

    static func failure(_ code: AnalysisErrorCode?) -> String {
        switch code {
        case .emptyScript: "대본이 너무 짧아요. 세 글자 이상 적어 주세요."
        case .audioNotFound: "녹음 파일을 찾지 못했어요. 다시 녹음해 주세요."
        case .audioDecodeFailed: "녹음 파일을 읽지 못했어요. 다시 녹음해 주세요."
        case .audioTooShort: "녹음이 너무 짧아요. 1.5초 이상 녹음해 주세요."
        case .audioTooLong: "녹음이 너무 길어요. 10분 안으로 녹음해 주세요."
        case .noSpeech: "목소리가 들리지 않았어요. 마이크를 확인하고 다시 녹음해 주세요."
        case .alignmentLowCoverage: "대본과 녹음이 많이 달라요. 대본을 보며 다시 읽어 주세요."
        case .engineUnavailable, .internal, nil: fallbackError
        }
    }

    static func pitch(_ level: Int) -> String? {
        switch level {
        case 2: "아주 높게"
        case 1: "높게"
        case -1: "낮게"
        case -2: "아주 낮게"
        default: nil
        }
    }

    static func stretch(_ ratio: Double) -> String {
        "\(tenths(ratio))배 길게"
    }

    static func pause(_ durationMs: Int) -> String {
        "\(tenths(Double(durationMs) / 1000))초"
    }

    static func trend(_ difference: Int, unit: String) -> String {
        if difference == 0 { return "지난 연습과 같아요" }
        return "지난 연습보다 \(abs(difference))\(unit) \(difference < 0 ? "줄었어요" : "늘었어요")"
    }

    private static func tenths(_ value: Double) -> String {
        String(format: "%.1f", locale: Locale(identifier: "en_US_POSIX"), value)
    }
}
