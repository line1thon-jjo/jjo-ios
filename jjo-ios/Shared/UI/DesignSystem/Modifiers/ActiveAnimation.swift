//
//  ActiveAnimation.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

struct ActiveAnimation: ViewModifier {
    let isActive: Bool
    let animation: Animation
    var delay: TimeInterval = 0
    var exitAnimation: Animation = Motion.base

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.animation(reduceMotion ? nil : isActive ? animation.delay(delay) : exitAnimation, value: isActive)
    }
}

extension View {
    func activeAnimation(
        _ isActive: Bool,
        _ animation: Animation,
        delay: TimeInterval = 0,
        exit: Animation = Motion.base
    ) -> some View {
        modifier(ActiveAnimation(isActive: isActive, animation: animation, delay: delay, exitAnimation: exit))
    }
}
