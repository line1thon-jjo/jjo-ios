//
//  FeedbackKind.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated enum FeedbackKind: String, Codable, Sendable, CaseIterable {
    case endRise = "END_RISE"
    case endStretch = "END_STRETCH"
    case endFade = "END_FADE"
    case midStretch = "MID_STRETCH"
    case midPause = "MID_PAUSE"
    case longPause = "LONG_PAUSE"
    case noBreak = "NO_BREAK"
    case pace = "PACE"
    case pause = "PAUSE"
}

nonisolated extension FeedbackKind {
    init(habit: HabitType) {
        self = switch habit {
        case .endRise: .endRise
        case .endStretch: .endStretch
        case .endFade: .endFade
        case .midStretch: .midStretch
        case .midPause: .midPause
        case .longPause: .longPause
        case .noBreak: .noBreak
        }
    }

    var isPause: Bool {
        self == .pause || self == .midPause || self == .longPause
    }

    // 문제 위치가 글자가 아니라 "이 글자 뒤"(쉼, 쉬지 않음)인 종류
    var isGap: Bool {
        isPause || self == .noBreak
    }
}
