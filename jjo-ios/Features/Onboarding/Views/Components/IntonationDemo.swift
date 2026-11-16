//
//  IntonationDemo.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

struct IntonationDemo: View {
    let isActive: Bool

    var body: some View {
        HStack(spacing: 32 * 0.3) {
            Text("나의")

            HStack(spacing: 0) {
                Text("말")
                Text("투")
                    .scaleEffect(x: isActive ? 1.9 : 1, anchor: .leading)
                    .activeAnimation(isActive, Motion.spring, delay: 0.24)
            }
            .padding(.trailing, 32 * 0.9)
        }
        .font_32_bold(.ink)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("나의 말투")
    }
}

#Preview {
    @Previewable @State var isActive = false

    IntonationDemo(isActive: isActive)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.backgroundOnboarding)
        .onTapGesture { isActive.toggle() }
        .onAppear { isActive = true }
}
