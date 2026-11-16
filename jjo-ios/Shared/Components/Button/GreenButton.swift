//
//  GreenButton.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

struct GreenButton: View {
    let text: String
    var showArrow = true
    var isDisabled = false
    let action: () -> Void

    init(_ text: String, showArrow: Bool = true, isDisabled: Bool = false, action: @escaping () -> Void) {
        self.text = text
        self.showArrow = showArrow
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button {
            Haptics.press()
            action()
        } label: {
            Text(text)
        }
        .buttonStyle(GreenButtonStyle(showArrow: showArrow))
        .disabled(isDisabled)
    }
}

struct GreenButtonStyle: ButtonStyle {
    var showArrow = true

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed && isEnabled

        HStack(spacing: Spacing.x3) {
            configuration.label
                .pretendard(.bold, 17, .pureBlack, lineHeight: .natural, tracking: false)
                .lineLimit(1)

            Spacer(minLength: 0)

            if showArrow {
                Icon(.iconArrowRight, size: IconSize.medium, color: .pureBlack)
                    .offset(x: arrowOffset(isPressed: isPressed))
                    .animation(reduceMotion ? nil : Motion.overshoot, value: isPressed)
                    .animation(reduceMotion ? nil : Motion.overshoot, value: isEnabled)
            }
        }
        .padding(.horizontal, Spacing.x5)
        .frame(maxWidth: .infinity)
        .frame(height: Layout.greenButtonHeight)
        .background(Color.lime)
        .contentShape(Rectangle())
        .opacity(isEnabled ? 1 : 0.5)
        .scaleEffect(isPressed ? 0.98 : 1)
        .animation(Motion.fast, value: isPressed)
        .animation(Motion.slow, value: isEnabled)
    }

    private func arrowOffset(isPressed: Bool) -> CGFloat {
        if !isEnabled { -6 } else if isPressed { 4 } else { 0 }
    }
}

#Preview {
    VStack(spacing: Spacing.x4) {
        GreenButton("다음") {}
        GreenButton("시작하기", isDisabled: true) {}
        GreenButton("계속 쓸게요", showArrow: false) {}
    }
    .padding(Spacing.screenHorizontal)
    .background(Color.background)
}
