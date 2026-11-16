//
//  Motion.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

nonisolated enum Motion {
    enum Duration {
        static let fast: TimeInterval = 0.12
        static let base: TimeInterval = 0.2
        static let slow: TimeInterval = 0.32
    }

    static let fast = standard(Duration.fast)
    static let base = standard(Duration.base)
    static let slow = standard(Duration.slow)
    static let spring = Animation.interpolatingSpring(mass: 1, stiffness: 260, damping: 18)
    static let overshoot = Animation.timingCurve(0.34, 1.56, 0.64, 1, duration: Duration.slow)

    static let fadeUp = standard(0.48)
    static let drawX = standard(0.56)
    static let growWidth = standard(0.52)
    static let pop = standard(0.64)
    static let reveal = standard(0.52)
    static let collapse = Animation.timingCurve(0.4, 0, 0.2, 1, duration: 0.44)
    static let shimmer = Animation.linear(duration: 1.4).repeatForever(autoreverses: false)

    static let fadeUpOffset: CGFloat = 8
    static let popScale: CGFloat = 0.92

    static func standard(_ duration: TimeInterval) -> Animation {
        .timingCurve(0.2, 0, 0, 1, duration: duration)
    }
}

nonisolated extension Animation {
    func unlessReduced(_ reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : self
    }
}
