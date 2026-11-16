//
//  OnboardingSlide.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated struct OnboardingSlide: Identifiable, Hashable, Sendable {
    enum Demo: Sendable {
        case intonation
        case breath
        case retry
    }

    let id: Int
    let title: String
    let description: String
    let demo: Demo

    static let all: [OnboardingSlide] = [
        OnboardingSlide(
            id: 0,
            title: "말투가 글자 모양으로 보여요",
            description: "높게 말한 글자는 위로,\n길게 늘인 음절은 가로로 길어져요.",
            demo: .intonation
        ),
        OnboardingSlide(
            id: 1,
            title: "쉼과 속도도 놓치지 않아요",
            description: "숨을 쉰 위치는 간격으로,\n평소보다 빠르거나 느린 구절은 밑줄로 보여요.",
            demo: .breath
        ),
        OnboardingSlide(
            id: 2,
            title: "한 곳씩 바꾸며 다시 말해요",
            description: "가장 먼저 연습할 구간을 듣고,\n같은 대본으로 다시 녹음해 비교하세요.",
            demo: .retry
        )
    ]
}
