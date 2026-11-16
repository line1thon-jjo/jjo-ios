//
//  UtteranceGuide.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

struct UtteranceGuide: View {
    private enum Kind: String, CaseIterable, Identifiable {
        case pitch
        case stretch
        case fast
        case slow
        case pause

        var id: String { rawValue }

        var label: String {
            switch self {
            case .pitch: "높낮이"
            case .stretch: "늘임"
            case .fast: "빠름"
            case .slow: "느림"
            case .pause: "쉼"
            }
        }

        var sample: String {
            switch self {
            case .pitch: "높"
            case .stretch: "길"
            case .fast: "빠른말"
            case .slow: "느린말"
            case .pause: "0.8초"
            }
        }

        var description: String {
            switch self {
            case .pitch: "평소보다 높게 말한 글자는 위로, 낮게 말한 글자는 아래로 움직여요."
            case .stretch: "평소보다 길게 끈 글자는 가로로 늘어나요."
            case .fast: "평소보다 빠른 구절은 글자가 촘촘하고 빨간 밑줄이 그어져요."
            case .slow: "평소보다 느린 구절은 글자가 넓게 퍼지고 파란 밑줄이 그어져요."
            case .pause: "문장 중간에서 쉰 곳은 간격이 벌어지고 쉰 시간이 보여요."
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.x5) {
            ForEach(Kind.allCases) { kind in
                HStack(alignment: .top, spacing: Spacing.x4) {
                    sample(kind)
                        .frame(width: 64, height: 40)
                        .background(Color.surfaceSample, in: RoundedRectangle(cornerRadius: 10))
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(kind.label)
                            .font_15_semibold(.ink)
                        Text(kind.description)
                            .font_14_regular(.textBody, lineHeight: .percent150)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    @ViewBuilder
    private func sample(_ kind: Kind) -> some View {
        switch kind {
        case .pitch:
            Text(kind.sample)
                .pretendard(.semiBold, 18, .ink, lineHeight: .natural)
                .offset(y: -6)
        case .stretch:
            Text(kind.sample)
                .pretendard(.semiBold, 18, .ink, lineHeight: .natural)
                .scaleEffect(x: 1.8, anchor: .leading)
                .padding(.trailing, 18 * 0.72)
        case .fast:
            paceSample(kind.sample, kerning: 14 * -0.09, color: .paceFast.opacity(0.8))
        case .slow:
            paceSample(kind.sample, kerning: 14 * 0.06, color: .paceSlow.opacity(0.7))
        case .pause:
            Text(kind.sample)
                .pretendard(.semiBold, 12, .ink, lineHeight: .natural)
        }
    }

    private func paceSample(_ text: String, kerning: CGFloat, color: Color) -> some View {
        Text(text)
            .font(.custom(Pretendard.regular.rawValue, fixedSize: 14))
            .kerning(kerning)
            .foregroundStyle(Color.ink)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(color)
                    .frame(height: 2)
                    .offset(y: 3)
            }
    }
}

#Preview {
    UtteranceGuide()
        .padding(Spacing.screenHorizontal)
}
