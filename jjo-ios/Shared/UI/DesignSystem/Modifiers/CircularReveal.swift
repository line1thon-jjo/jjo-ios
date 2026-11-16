//
//  CircularReveal.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

struct RevealCircle: Shape {
    var progress: CGFloat
    let origin: UnitPoint
    var minRadius: CGFloat = 28

    nonisolated var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    nonisolated func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.minX + rect.width * origin.x, y: rect.minY + rect.height * origin.y)
        let corners = [
            CGPoint(x: rect.minX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.minY),
            CGPoint(x: rect.minX, y: rect.maxY),
            CGPoint(x: rect.maxX, y: rect.maxY)
        ]
        let maxRadius = corners.map { hypot($0.x - center.x, $0.y - center.y) }.max() ?? 0
        let radius = minRadius + (maxRadius - minRadius) * progress

        return Path(ellipseIn: CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        ))
    }
}

struct CircularReveal: ViewModifier {
    let isRevealed: Bool
    let origin: UnitPoint

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let fadeOut = Animation.easeIn(duration: 0.12).delay(0.3)

    func body(content: Content) -> some View {
        content
            .animation(reduceMotion ? nil : isRevealed ? Motion.reveal : Motion.collapse) {
                $0.clipShape(RevealCircle(progress: isRevealed ? 1 : 0, origin: origin))
            }
            .animation(reduceMotion || isRevealed ? nil : Self.fadeOut) {
                $0.opacity(isRevealed ? 1 : 0)
            }
    }
}

extension View {
    func circularReveal(isRevealed: Bool, origin: UnitPoint) -> some View {
        modifier(CircularReveal(isRevealed: isRevealed, origin: origin))
    }
}

#Preview {
    @Previewable @State var isRevealed = false

    ZStack {
        Color.background
        Color.lime
            .circularReveal(isRevealed: isRevealed, origin: UnitPoint(x: 0.85, y: 0.9))
        Button("toggle") { isRevealed.toggle() }
            .font_16_medium(.ink)
    }
    .ignoresSafeArea()
}
