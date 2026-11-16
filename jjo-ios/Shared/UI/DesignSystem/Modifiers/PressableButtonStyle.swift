//
//  PressableButtonStyle.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

struct PressableButtonStyle: ButtonStyle {
    var pressedOpacity: Double = 0.7
    var pressedScale: CGFloat = 1

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? pressedOpacity : 1)
            .scaleEffect(configuration.isPressed ? pressedScale : 1)
            .animation(Motion.base, value: configuration.isPressed)
            .contentShape(Rectangle())
    }
}

extension ButtonStyle where Self == PressableButtonStyle {
    static var pressable: PressableButtonStyle { PressableButtonStyle() }

    static func pressable(opacity: Double = 0.7, scale: CGFloat = 1) -> PressableButtonStyle {
        PressableButtonStyle(pressedOpacity: opacity, pressedScale: scale)
    }
}

#Preview {
    VStack(spacing: Spacing.x6) {
        Button("opacity") {}
            .buttonStyle(.pressable)
        Button("scale") {}
            .buttonStyle(.pressable(opacity: 1, scale: 0.94))
    }
    .font_16_medium(.ink)
    .padding()
}
