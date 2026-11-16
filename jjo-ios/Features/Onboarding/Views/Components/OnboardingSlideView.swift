//
//  OnboardingSlideView.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

struct OnboardingSlideView: View {
    let slide: OnboardingSlide
    let isActive: Bool

    var body: some View {
        VStack(spacing: 34) {
            ZStack {
                Ellipse()
                    .fill(EllipticalGradient.onboardingGlow)
                    .frame(maxWidth: 323)
                    .frame(height: 305)
                    .scaleEffect(isActive ? 1 : Motion.popScale)
                    .activeAnimation(isActive, Motion.pop, exit: Motion.slow)
                    .accessibilityHidden(true)

                demo
            }
            .frame(height: 265)
            .frame(maxWidth: .infinity)

            VStack(spacing: Spacing.x4) {
                Text(slide.title)
                    .font_26_bold(.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .accessibilityAddTraits(.isHeader)

                Text(slide.description)
                    .font_14_regular(.textBody, lineHeight: .percent150)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, Spacing.screenHorizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    private var demo: some View {
        switch slide.demo {
        case .intonation: IntonationDemo(isActive: isActive)
        case .breath: BreathDemo(isActive: isActive)
        case .retry: RetryDemo(isActive: isActive)
        }
    }
}

#Preview("말투") {
    OnboardingSlideView(slide: OnboardingSlide.all[0], isActive: true)
        .background(Color.backgroundOnboarding)
}

#Preview("쉼과 속도") {
    OnboardingSlideView(slide: OnboardingSlide.all[1], isActive: true)
        .background(Color.backgroundOnboarding)
}

#Preview("다시 말하기") {
    OnboardingSlideView(slide: OnboardingSlide.all[2], isActive: true)
        .background(Color.backgroundOnboarding)
}
