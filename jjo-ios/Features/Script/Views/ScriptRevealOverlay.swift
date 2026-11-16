//
//  ScriptRevealOverlay.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

struct ScriptRevealOverlay: View {
    @Environment(ScriptReveal.self) private var reveal

    var body: some View {
        GeometryReader { proxy in
            if reveal.isCovering, let origin = reveal.origin {
                let frame = proxy.frame(in: .global)

                ScriptView(viewModel: reveal.viewModel, isSnapshot: true)
                    .circularReveal(
                        isRevealed: reveal.isRevealed,
                        origin: UnitPoint(
                            x: (origin.x - frame.minX) / max(frame.width, 1),
                            y: (origin.y - frame.minY) / max(frame.height, 1)
                        )
                    )
                    .accessibilityHidden(true)
            }
        }
        .allowsHitTesting(reveal.isCovering)
    }
}
