//
//  BrandLayout.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

struct BrandLayout<Content: View, Footer: View>: View {
    var intro = false
    @ViewBuilder let content: () -> Content
    @ViewBuilder let footer: () -> Footer

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase = 0
    @State private var isTextVisible = false

    private let logoSize = CGSize(width: 78.2222, height: 72.1111)
    private let brandHeight: CGFloat = 88
    private let accentTop: CGFloat = 65
    private let accentHeight: CGFloat = 23
    private let accentLeading: CGFloat = 80

    var body: some View {
        GeometryReader { proxy in
            let screenHeight = proxy.size.height + proxy.safeAreaInsets.top + proxy.safeAreaInsets.bottom
            let topPadding = min(max(screenHeight * 0.3, 104), 276) - proxy.safeAreaInsets.top
            let contentWidth = proxy.size.width - Spacing.screenHorizontal * 2

            VStack(alignment: .leading, spacing: 0) {
                brand(contentWidth: contentWidth)

                Text("내가 몰랐던 내 말버릇까지")
                    .font_20_semibold(.ink)
                    .padding(.top, 31)
                    .padding(.bottom, 64)
                    .fadeUp(isActive: isSettled || isTextVisible, delay: 0.84)

                content()
                    .fadeUp(isActive: isSettled || isTextVisible, delay: 0.92)

                Spacer(minLength: Spacing.x10)

                if Footer.self != EmptyView.self {
                    footer()
                        .padding(.top, Spacing.x4)
                        .padding(
                            .bottom,
                            proxy.safeAreaInsets.bottom > 0 ? Spacing.bottomAction : Spacing.bottomActionFromEdge
                        )
                        .fadeUp(isActive: isSettled || isTextVisible, delay: 1)
                }
            }
            .padding(.top, max(topPadding, 0))
            .padding(.horizontal, Spacing.screenHorizontal)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .background(Color.background.ignoresSafeArea())
        .task { await runIntro() }
    }

    private var isSettled: Bool { !intro || reduceMotion }

    private func brand(contentWidth: CGFloat) -> some View {
        let width = contentWidth + Spacing.screenHorizontal

        return ZStack(alignment: .topLeading) {
            Image(.logoJjoLarge)
                .resizable()
                .frame(width: logoSize.width, height: logoSize.height)
                .offset(x: logoOffset(width: width))
                .accessibilityLabel("jjo")

            BrandAccent(leading: accentOffset(width: width))
                .fill(Color.lime)
                .frame(width: width, height: accentHeight)
                .offset(y: accentTop)
                .accessibilityHidden(true)
        }
        .frame(width: contentWidth, height: brandHeight, alignment: .topLeading)
    }

    private func logoOffset(width: CGFloat) -> CGFloat {
        isSettled || phase == 2 ? 0 : width * 0.5 - 49
    }

    private func accentOffset(width: CGFloat) -> CGFloat {
        if isSettled || phase == 2 {
            accentLeading
        } else if phase == 1 {
            width * 0.5 + 31
        } else {
            width + 14
        }
    }

    private func runIntro() async {
        guard !isSettled else { return }

        isTextVisible = true
        try? await Task.sleep(for: .milliseconds(240))
        withAnimation(Motion.standard(0.228)) { phase = 1 }
        try? await Task.sleep(for: .milliseconds(228))
        withAnimation(Motion.standard(0.532)) { phase = 2 }
    }
}

extension BrandLayout where Footer == EmptyView {
    init(intro: Bool = false, @ViewBuilder content: @escaping () -> Content) {
        self.init(intro: intro, content: content) { EmptyView() }
    }
}

#Preview("기본") {
    BrandLayout {
        BrandDescription()
    } footer: {
        GreenButton("시작하기") {}
    }
}

#Preview("인트로") {
    BrandLayout(intro: true) {
        BrandDescription()
    }
}
