//
//  SkeletonBlock.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

struct SkeletonBlock: View {
    var widthRatio: CGFloat = 1
    var height: CGFloat = 16

    var body: some View {
        GeometryReader { proxy in
            RoundedRectangle(cornerRadius: Radius.skeleton)
                .fill(Color.skeletonBase)
                .shimmer()
                .frame(width: proxy.size.width * widthRatio)
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 10) {
        SkeletonBlock(widthRatio: 0.6)
        SkeletonBlock(widthRatio: 0.35)
    }
    .padding(.vertical, 22)
    .padding(.horizontal, Spacing.screenHorizontal)
    .background(Color.background)
}
