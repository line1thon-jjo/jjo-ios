//
//  AppSplash.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

struct AppSplash: View {
    var introDuration: Duration = .milliseconds(1250)
    let onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isLeaving = false

    var body: some View {
        BrandLayout(intro: true) {
            BrandDescription()
        }
        .opacity(isLeaving ? 0 : 1)
        .allowsHitTesting(!isLeaving)
        .accessibilityHidden(true)
        .task {
            try? await Task.sleep(for: reduceMotion ? .milliseconds(600) : introDuration)
            withAnimation(Motion.slow) { isLeaving = true }
            try? await Task.sleep(for: .milliseconds(320))
            onFinish()
        }
    }
}

#Preview {
    @Previewable @State var isFinished = false

    ZStack {
        Text("홈")
            .font_20_semibold(.ink)
        if !isFinished {
            AppSplash { isFinished = true }
        }
    }
}
