//
//  HeaderView.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

struct HeaderView: View {
    enum Leading {
        case logo
        case back(() -> Void)
    }

    var leading: Leading = .logo
    var isMenuOpen = false
    var onMenu: (() -> Void)?

    var body: some View {
        HStack {
            switch leading {
            case .logo:
                Image(.logoJjo)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: Layout.headerLogoHeight)
                    .accessibilityLabel("jjo")
            case .back(let action):
                Button(action: action) {
                    Icon(.iconArrowLeft, size: Layout.headerButton, color: .textIcon)
                        .padding((Layout.touchTarget - Layout.headerButton) / 2)
                        .contentShape(Rectangle())
                        .padding(-(Layout.touchTarget - Layout.headerButton) / 2)
                }
                .buttonStyle(.pressable)
                .accessibilityLabel("뒤로 가기")
            }

            Spacer(minLength: 0)

            if let onMenu {
                BurgerButton(isOpen: isMenuOpen, action: onMenu)
            }
        }
        .padding(.horizontal, Spacing.screenHorizontal)
        .frame(height: Layout.headerHeight)
        .frame(maxWidth: .infinity)
        .background(Color.background)
    }
}

#Preview {
    VStack(spacing: Spacing.x4) {
        HeaderView(onMenu: {})
        HeaderView(leading: .back {}, onMenu: {})
        HeaderView(leading: .back {})
        HeaderView(isMenuOpen: true, onMenu: {})
    }
    .frame(maxHeight: .infinity, alignment: .top)
    .background(Color.surfaceMuted)
}
