//
//  PaceToolbar.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

struct PaceToolbar: View {
    let speed: SpeedCounts
    let focusPace: UtteranceAnalysis.PaceLabel?
    let onToggle: (UtteranceAnalysis.PaceLabel) -> Void
    let onGuide: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack {
            HStack(spacing: 14) {
                paceButton(.fast, label: "빠른 구절", count: speed.fast, color: .paceFast.opacity(0.8))
                paceButton(.slow, label: "느린 구절", count: speed.slow, color: .paceSlow.opacity(0.7))
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("구간 강조")

            Spacer(minLength: Spacing.x3)

            Button(action: onGuide) {
                HStack(spacing: Spacing.x1) {
                    Icon(.iconInfo, size: IconSize.medium, color: .textMoss)
                    Text("보는 법")
                        .font_14_medium(.textMoss)
                }
                .padding(.vertical, Spacing.x1)
            }
            .buttonStyle(.pressable)
        }
    }

    private func paceButton(
        _ pace: UtteranceAnalysis.PaceLabel, label: String, count: Int, color: Color
    ) -> some View {
        let isPressed = focusPace == pace
        let opacity = if count == 0 { 0.35 } else if focusPace != nil, !isPressed { 0.45 } else { 1.0 }

        return Button {
            Haptics.select()
            onToggle(pace)
        } label: {
            Text("\(label) \(count)곳")
                .pretendard(isPressed ? .bold : .medium, 14, isPressed ? .ink : .textBody)
                .padding(.bottom, 2)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(color)
                        .frame(height: 2)
                        .offset(y: 2)
                }
                .padding(.bottom, 2)
        }
        .buttonStyle(.plain)
        .disabled(count == 0)
        .opacity(opacity)
        .animation(reduceMotion ? nil : Motion.base, value: focusPace)
        .accessibilityAddTraits(isPressed ? .isSelected : [])
    }
}

#Preview {
    @Previewable @State var focus: UtteranceAnalysis.PaceLabel? = .fast

    PaceToolbar(
        speed: SpeedCounts(fast: 5, normal: 7, slow: 0, measured: 12),
        focusPace: focus,
        onToggle: { focus = focus == $0 ? nil : $0 },
        onGuide: {}
    )
    .padding(Spacing.screenHorizontal)
    .background(Color.background)
}
