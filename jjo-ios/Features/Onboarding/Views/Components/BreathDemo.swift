//
//  BreathDemo.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

struct BreathDemo: View {
    let isActive: Bool

    private let lineHeight: CGFloat = 32 * 1.3
    private let pauseWidth: CGFloat = 54

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.x2) {
            Text("천천히")

            HStack(alignment: .bottom, spacing: 0) {
                Text("또렷")
                pause
                Text("하게")
            }
            .padding(.bottom, 5)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color.paceFast)
                    .frame(height: 2)
                    .scaleEffect(x: isActive ? 1 : 0, anchor: .leading)
                    .activeAnimation(isActive, Motion.drawX, delay: 0.72)
            }
        }
        .font_32_bold(.ink)
        .fixedSize()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("천천히 또렷하게. 또렷과 하게 사이에서 0.8초 쉼")
    }

    private var pause: some View {
        ZStack(alignment: .top) {
            PauseDots()
                .stroke(Color.ink, style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [0, 4]))
                .frame(height: 2)
                .padding(.horizontal, 4)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 32 * 0.62 - 2)

            Text("0.8초")
                .font_10_medium(.textBody, lineHeight: .points(13))
                .fixedSize()
                .padding(.top, 32 * 0.15)
        }
        .frame(width: isActive ? pauseWidth : 0, height: lineHeight)
        .clipped()
        .activeAnimation(isActive, Motion.growWidth, delay: 0.24)
    }
}

private struct PauseDots: Shape {
    nonisolated func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + 1, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

#Preview {
    @Previewable @State var isActive = false

    BreathDemo(isActive: isActive)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.backgroundOnboarding)
        .onTapGesture { isActive.toggle() }
        .onAppear { isActive = true }
}
