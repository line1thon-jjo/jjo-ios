//
//  OnboardingView.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

struct OnboardingView: View {
    let isReplay: Bool
    let initialPage: Int
    let onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var position: ScrollPosition
    @State private var hasAppeared = false

    private let slides = OnboardingSlide.all

    init(isReplay: Bool = false, initialPage: Int = 0, onFinish: @escaping () -> Void) {
        self.isReplay = isReplay
        self.initialPage = initialPage
        self.onFinish = onFinish
        _position = State(initialValue: ScrollPosition(id: initialPage))
    }

    private var currentIndex: Int { position.viewID(type: Int.self) ?? 0 }
    private var isLast: Bool { currentIndex == slides.count - 1 }

    var body: some View {
        GeometryReader { proxy in
            let screenHeight = proxy.size.height + proxy.safeAreaInsets.top + proxy.safeAreaInsets.bottom

            VStack(spacing: 0) {
                header

                ScrollView(.horizontal) {
                    HStack(spacing: 0) {
                        ForEach(slides) { slide in
                            OnboardingSlideView(slide: slide, isActive: hasAppeared && slide.id == currentIndex)
                                .padding(.top, min(max(screenHeight * 0.06, 16), 56))
                                .containerRelativeFrame(.horizontal)
                                .id(slide.id)
                                .accessibilityHidden(slide.id != currentIndex)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .scrollPosition($position)
                .scrollIndicators(.hidden)
                .frame(maxHeight: .infinity)

                bottom
                    .padding(
                        .bottom,
                        proxy.safeAreaInsets.bottom > 0 ? Spacing.bottomAction : Spacing.bottomActionFromEdge
                    )
            }
        }
        .background(Color.backgroundOnboarding.ignoresSafeArea())
        .onAppear {
            position.scrollTo(id: initialPage)
            hasAppeared = true
        }
        .onChange(of: currentIndex) { Haptics.select() }
    }

    private var header: some View {
        HStack {
            Spacer(minLength: 0)
            TextButton(isReplay ? "닫기" : "건너뛰기", action: onFinish)
                .opacity(isLast ? 0 : 1)
                .allowsHitTesting(!isLast)
                .accessibilityHidden(isLast)
                .animation(reduceMotion ? nil : Motion.base, value: isLast)
        }
        .padding(.top, Spacing.x4)
        .padding(.horizontal, Spacing.screenHorizontal)
    }

    private var bottom: some View {
        VStack(spacing: Spacing.x10) {
            PageIndicator(count: slides.count, current: currentIndex, onSelect: goTo)

            GreenButton(isLast ? "시작하기" : "다음") {
                if isLast {
                    onFinish()
                } else {
                    goTo(currentIndex + 1)
                }
            }
        }
        .padding(.top, Spacing.x6)
        .padding(.horizontal, Spacing.screenHorizontal)
    }

    private func goTo(_ index: Int) {
        withAnimation(reduceMotion ? nil : .smooth) { position.scrollTo(id: index) }
    }
}

#Preview("처음") {
    OnboardingView {}
}

#Preview("다시 보기") {
    OnboardingView(isReplay: true) {}
}
