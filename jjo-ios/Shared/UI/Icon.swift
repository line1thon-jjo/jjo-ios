//
//  Icon.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

struct Icon: View {
    let resource: ImageResource
    var size: CGFloat = IconSize.medium
    var color: Color = .textIcon

    init(_ resource: ImageResource, size: CGFloat = IconSize.medium, color: Color = .textIcon) {
        self.resource = resource
        self.size = size
        self.color = color
    }

    var body: some View {
        Image(resource)
            .resizable()
            .renderingMode(.template)
            .aspectRatio(contentMode: .fit)
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

#Preview {
    HStack(spacing: Spacing.x4) {
        Icon(.iconArrowLeft, size: IconSize.large)
        Icon(.iconArrowRight, color: .pureBlack)
        Icon(.iconChevronRight)
        Icon(.iconEdit, size: IconSize.small)
        Icon(.iconInfo)
        Icon(.iconMic, color: .pureBlack)
        Icon(.iconPlus, color: .pureBlack)
        Icon(.iconRetry, color: .ink)
        Icon(.iconUpload, size: IconSize.small)
    }
    .padding()
    .background(Color.background)
}
