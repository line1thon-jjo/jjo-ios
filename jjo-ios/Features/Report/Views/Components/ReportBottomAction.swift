//
//  ReportBottomAction.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

struct ReportBottomAction: View {
    let isDisabled: Bool
    let action: () -> Void

    private static let fade: CGFloat = 32

    var body: some View {
        GreenButton("다시 녹음하기", isDisabled: isDisabled, action: action)
            .padding(.top, Self.fade)
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.bottom, Spacing.bottomAction)
            .background {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .overlay(Color.veilLight)
                    .mask {
                        VStack(spacing: 0) {
                            LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                                .frame(height: Self.fade)
                            Color.black
                        }
                    }
                    .ignoresSafeArea(edges: .bottom)
                    .allowsHitTesting(false)
            }
    }
}

#Preview {
    Color.background
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ReportBottomAction(isDisabled: false) {}
        }
}
