//
//  Shimmer.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

struct Shimmer: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { proxy in
                    LinearGradient(
                        colors: [.skeletonBase, .skeletonHighlight, .skeletonBase, .skeletonHighlight, .skeletonBase],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: proxy.size.width * 2)
                    .offset(x: -proxy.size.width * phase)
                }
                .mask(content)
            }
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(Motion.shimmer) { phase = 1 }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(Shimmer())
    }
}

#Preview {
    RoundedRectangle(cornerRadius: Radius.skeleton)
        .fill(Color.skeletonBase)
        .frame(height: 16)
        .shimmer()
        .padding()
}
