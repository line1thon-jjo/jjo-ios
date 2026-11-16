//
//  PillButton.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

struct PillButton: View {
    enum Variant {
        case compact
        case wide
    }

    let text: String
    var icon: ImageResource?
    var variant: Variant = .compact
    let action: () -> Void

    init(_ text: String, icon: ImageResource? = nil, variant: Variant = .compact, action: @escaping () -> Void) {
        self.text = text
        self.icon = icon
        self.variant = variant
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.x2) {
                label
                if let icon {
                    Icon(icon, size: IconSize.small, color: .pureBlack)
                }
            }
            .padding(.horizontal, variant == .compact ? 18 : 0)
            .padding(.vertical, variant == .compact ? 10 : 0)
            .frame(maxWidth: variant == .wide ? .infinity : nil)
            .frame(height: variant == .wide ? Layout.pillButtonHeight : nil)
            .background(Color.surface, in: Capsule())
            .overlay(Capsule().strokeBorder(variant == .compact ? Color.lineZinc : Color.line, lineWidth: 1))
        }
        .buttonStyle(.pressable)
    }

    @ViewBuilder
    private var label: some View {
        switch variant {
        case .compact: Text(text).font_14_semibold(.ink)
        case .wide: Text(text).pretendard(.medium, 13, .pureBlack, lineHeight: .natural, tracking: false)
        }
    }
}

#Preview {
    VStack(spacing: Spacing.x4) {
        PillButton("다시 시도") {}
        PillButton("대본 파일 불러오기", icon: .iconUpload, variant: .wide) {}
    }
    .padding(Spacing.screenHorizontal)
    .background(Color.background)
}
