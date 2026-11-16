//
//  RetryDemo.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

struct RetryDemo: View {
    let isActive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            row(label: "이전", text: "빠르게 지나갔어요", weight: .regular)

            row(label: "지금", text: "천천히 강조했어요", weight: .bold)
                .fadeUp(isActive: isActive, delay: 0.48, animation: Motion.fadeUp)
        }
        .accessibilityElement(children: .combine)
    }

    private func row(label: String, text: String, weight: Pretendard) -> some View {
        HStack(spacing: Spacing.x5) {
            Text(label)
                .pretendard(.regular, 15, .textBody)
            Text(text)
                .pretendard(weight, 20, .ink)
        }
    }
}

#Preview {
    @Previewable @State var isActive = false

    RetryDemo(isActive: isActive)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.backgroundOnboarding)
        .onTapGesture { isActive.toggle() }
        .onAppear { isActive = true }
}
