//
//  TextButton.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

struct TextButton: View {
    enum Variant {
        case plain
        case underline
        case destructive
    }

    let text: String
    var variant: Variant = .plain
    var isDisabled = false
    let action: () -> Void

    init(_ text: String, variant: Variant = .plain, isDisabled: Bool = false, action: @escaping () -> Void) {
        self.text = text
        self.variant = variant
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            label
        }
        .buttonStyle(.pressable)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1)
    }

    @ViewBuilder
    private var label: some View {
        switch variant {
        case .plain:
            Text(text)
                .font_14_medium(.textMuted)
                .padding(.vertical, Spacing.x2)
        case .underline:
            Text(text)
                .underline()
                .font_14_regular(.textSubtle)
                .padding(.vertical, Spacing.x2)
        case .destructive:
            Text(text)
                .font_16_medium(.destructive)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    VStack(spacing: Spacing.x4) {
        TextButton("건너뛰기") {}
        TextButton("모든 기록 지우기", variant: .underline) {}
        TextButton("지우기", variant: .destructive) {}
        TextButton("지우는 중", variant: .destructive, isDisabled: true) {}
    }
    .padding(Spacing.screenHorizontal)
    .background(Color.background)
}
