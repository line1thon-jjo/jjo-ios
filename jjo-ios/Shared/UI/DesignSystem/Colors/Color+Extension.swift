//
//  Color+Extension.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

nonisolated extension Color {
    static let ink = Color(hex: 0x09090B)
    static let pureBlack = Color(hex: 0x000000)
    static let pureWhite = Color(hex: 0xFFFFFF)

    static let background = Color(hex: 0xFAFAFA)
    static let backgroundOnboarding = Color(hex: 0xF7F8F4)
    static let surface = Color(hex: 0xFFFFFF)
    static let surfaceMuted = Color(hex: 0xF2F3EF)
    static let surfaceSample = Color(hex: 0xF4F6EF)
    static let surfaceChip = Color(hex: 0xEEF2E4)
    static let surfaceAvatar = Color(hex: 0xE9EEDF)

    static let lime = Color(hex: 0xD9F768)
    static let limeStatus = Color(hex: 0xB5D22E)
    static let olive = Color(hex: 0x648508)

    static let textStrong = Color(hex: 0x343434)
    static let textCharcoal = Color(hex: 0x2C2C2F)
    static let textSecondary = Color(hex: 0x3F3F46)
    static let textBody = Color(hex: 0x515151)
    static let textMoss = Color(hex: 0x4B5852)
    static let textIcon = Color(hex: 0x565656)
    static let textZinc = Color(hex: 0x71717A)
    static let textMuted = Color(hex: 0x7A7A82)
    static let textSubtle = Color(hex: 0x8A8A93)
    static let textGlyphMuted = Color(hex: 0x9A9A9E)
    static let textFaint = Color(hex: 0xA1A1AA)

    static let line = Color(hex: 0xECECEC)
    static let lineNeutral = Color(hex: 0xE5E5E5)
    static let lineZinc = Color(hex: 0xE4E4E7)
    static let lineMint = Color(hex: 0xE6ECE9)
    static let lineDashed = Color(hex: 0xC9C9CF)
    static let lineGray = Color(hex: 0xC9C9C9)
    static let lineStrong = Color(hex: 0x767676)
    static let hairline = Color(hex: 0x09090B, alpha: 0.07)
    static let indicatorIdle = Color(hex: 0xB8B8B8)

    static let skeletonBase = Color(hex: 0xEEEEEF)
    static let skeletonHighlight = Color(hex: 0xF6F6F7)

    static let paceFast = Color(hex: 0xAE3F41)
    static let paceSlow = Color(hex: 0x2F4AC4)
    static let destructive = Color(hex: 0xAE3F41)
    static let danger = Color(hex: 0xD93B3B)
    static let recordRed = Color(hex: 0xFF2D28)
    static let recordRedDark = Color(hex: 0x410307)
    static let recordDark = Color(hex: 0x2B2B2D)
    static let recordIdleDot = Color(hex: 0x565656)

    static let scrim = Color(hex: 0x09090B, alpha: 0.4)
    static let shadowFloating = Color(hex: 0x09090B, alpha: 0.18)
    static let shadowKnob = Color(hex: 0x09090B, alpha: 0.16)
    static let veil = Color(hex: 0xFAFAFA, alpha: 0.9)
    static let veilLight = Color(hex: 0xFAFAFA, alpha: 0.6)
}

nonisolated extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0

        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}

nonisolated extension EllipticalGradient {
    static let onboardingGlow = EllipticalGradient(
        stops: [
            .init(color: .lime, location: 0.48),
            .init(color: .lime.opacity(0.84), location: 0.61),
            .init(color: .lime.opacity(0.5), location: 0.74),
            .init(color: .lime.opacity(0.16), location: 0.87),
            .init(color: .lime.opacity(0), location: 1)
        ],
        center: .center,
        startRadiusFraction: 0,
        endRadiusFraction: 0.5
    )

    static let analyzingGlow = EllipticalGradient(
        stops: [
            .init(color: .lime, location: 0),
            .init(color: .lime.opacity(0.85), location: 0.32),
            .init(color: .lime.opacity(0.25), location: 0.58),
            .init(color: .lime.opacity(0), location: 0.72)
        ],
        center: .center,
        startRadiusFraction: 0,
        endRadiusFraction: 0.5
    )
}
