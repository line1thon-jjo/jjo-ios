//
//  BurgerButton.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

struct BurgerButton: View {
    let isOpen: Bool
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .top) {
                line
                    .rotationEffect(.degrees(isOpen ? 45 : 0))
                    .offset(y: isOpen ? 8 : 0)
                line
                    .opacity(isOpen ? 0 : 1)
                    .offset(y: 8)
                    .animation(reduceMotion ? nil : Motion.base, value: isOpen)
                line
                    .rotationEffect(.degrees(isOpen ? -45 : 0))
                    .offset(y: isOpen ? 8 : 16)
            }
            .frame(width: 22, height: 18, alignment: .top)
            .animation(reduceMotion ? nil : Motion.slow, value: isOpen)
            .frame(width: Layout.headerButton, height: Layout.headerButton)
            .padding((Layout.touchTarget - Layout.headerButton) / 2)
            .contentShape(Rectangle())
            .padding(-(Layout.touchTarget - Layout.headerButton) / 2)
        }
        .buttonStyle(.pressable)
        .accessibilityLabel(isOpen ? "메뉴 닫기" : "메뉴 열기")
    }

    private var line: some View {
        Rectangle()
            .fill(Color.textIcon)
            .frame(width: 22, height: 2)
    }
}

#Preview {
    @Previewable @State var isOpen = false

    BurgerButton(isOpen: isOpen) { isOpen.toggle() }
        .padding()
}
