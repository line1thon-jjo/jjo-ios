//
//  AnalyzingView.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

struct AnalyzingView: View {
    static let doneDuration: Duration = .milliseconds(1400)
    private static let leaveDelay: Duration = .milliseconds(1080)
    private static let glowSize: CGFloat = 480

    let isDone: Bool
    var detail = "잠시만 기다려 주세요."
    let onDone: () -> Void
    let onBack: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVisible = false
    @State private var isBreathing = false
    @State private var isFilled = false
    @State private var isLeaving = false

    var body: some View {
        VStack(spacing: 0) {
            HeaderView(leading: .back(onBack))
                .opacity(isDone ? 0 : 1)
                .animation(reduceMotion ? nil : Motion.base, value: isDone)

            VStack(spacing: Spacing.x3) {
                label
                Text(detail)
                    .font_14_regular(.textBody)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.x8)
                    .opacity(isDone ? 0 : 1)
                    .animation(reduceMotion ? nil : Motion.slow, value: isDone)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background { glow }
            .padding(.bottom, Spacing.x8 * 2)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(isDone ? "분석 완료!" : "분석 중. \(detail)")
        }
        .background(Color.background.ignoresSafeArea())
        .opacity(isVisible && !isLeaving ? 1 : 0)
        .allowsHitTesting(!isDone)
        .onAppear(perform: appear)
        .task(id: isDone) { await finish() }
    }

    private var label: some View {
        ZStack {
            Text("분석 중")
                .opacity(isDone ? 0 : 1)
                .offset(y: isDone && !reduceMotion ? -Motion.fadeUpOffset : 0)
                .animation(reduceMotion ? nil : Motion.slow, value: isDone)
            Text("분석 완료!")
                .opacity(isDone ? 1 : 0)
                .offset(y: isDone || reduceMotion ? 0 : Motion.fadeUpOffset)
                .animation(reduceMotion ? nil : Motion.slow.delay(0.16), value: isDone)
        }
        .font_20_bold(.ink)
    }

    private var glow: some View {
        Color.clear
            .overlay {
                Circle()
                    .fill(EllipticalGradient.analyzingGlow)
                    .frame(width: Self.glowSize, height: Self.glowSize)
                    .scaleEffect(isFilled ? 8 : isBreathing ? 1.05 : 0.5)
                    .opacity(isFilled || isBreathing ? 1 : 0.25)
            }
            .accessibilityHidden(true)
    }

    private func appear() {
        guard !reduceMotion else {
            isBreathing = true
            isVisible = true
            return
        }
        withAnimation(Motion.slow) { isVisible = true }
        withAnimation(Motion.standard(2.4).repeatForever(autoreverses: true)) { isBreathing = true }
    }

    private func finish() async {
        guard isDone else { return }
        AccessibilityNotification.Announcement("분석 완료!").post()
        Haptics.success()
        if !reduceMotion {
            withAnimation(Motion.standard(0.72)) { isFilled = true }
        }

        try? await Task.sleep(for: Self.leaveDelay)
        guard !Task.isCancelled else { return }
        withAnimation(reduceMotion ? nil : Motion.slow) { isLeaving = true }

        try? await Task.sleep(for: Self.doneDuration - Self.leaveDelay)
        guard !Task.isCancelled else { return }
        onDone()
    }
}

#Preview("분석 중") {
    AnalyzingView(isDone: false, onDone: {}, onBack: {})
}

#Preview("완료") {
    @Previewable @State var isDone = false

    AnalyzingView(isDone: isDone, onDone: {}, onBack: {})
        .onTapGesture { isDone = true }
}
