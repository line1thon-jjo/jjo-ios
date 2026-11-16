//
//  FadeUp.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

struct FadeUp: ViewModifier {
    let isActive: Bool
    var delay: TimeInterval = 0
    var animation: Animation = Motion.slow
    var exitAnimation: Animation = Motion.base
    var offset: CGFloat = Motion.fadeUpOffset

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(isActive ? 1 : 0)
            .offset(y: isActive || reduceMotion ? 0 : offset)
            .animation(reduceMotion ? nil : isActive ? animation.delay(delay) : exitAnimation, value: isActive)
    }
}

struct FadeUpOnAppear: ViewModifier {
    var delay: TimeInterval = 0

    @State private var isActive = false

    func body(content: Content) -> some View {
        content
            .modifier(FadeUp(isActive: isActive, delay: delay))
            .onAppear { isActive = true }
    }
}

extension View {
    func fadeUp(
        isActive: Bool,
        delay: TimeInterval = 0,
        animation: Animation = Motion.slow,
        offset: CGFloat = Motion.fadeUpOffset
    ) -> some View {
        modifier(FadeUp(isActive: isActive, delay: delay, animation: animation, offset: offset))
    }

    func fadeUpOnAppear(delay: TimeInterval = 0) -> some View {
        modifier(FadeUpOnAppear(delay: delay))
    }
}

#Preview {
    VStack(spacing: Spacing.x3) {
        Text("첫 번째").fadeUpOnAppear()
        Text("두 번째").fadeUpOnAppear(delay: 0.08)
        Text("세 번째").fadeUpOnAppear(delay: 0.16)
    }
    .font_16_medium(.ink)
    .padding()
}
