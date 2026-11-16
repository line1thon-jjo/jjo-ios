//
//  BottomSheet.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

struct BottomSheet<Content: View, Footer: View>: View {
    @Binding var isPresented: Bool
    let title: String
    var isDismissDisabled = false
    @ViewBuilder let content: () -> Content
    @ViewBuilder let footer: () -> Footer

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            let screenHeight = proxy.size.height + proxy.safeAreaInsets.top + proxy.safeAreaInsets.bottom

            ZStack(alignment: .bottom) {
                if isPresented {
                    Color.scrim
                        .ignoresSafeArea()
                        .onTapGesture(perform: dismiss)
                        .accessibilityLabel("닫기")
                        .accessibilityAddTraits(.isButton)
                        .transition(.opacity)

                    panel(hasBottomInset: proxy.safeAreaInsets.bottom > 0)
                        .frame(
                            maxHeight: screenHeight * Layout.sheetMaxHeightRatio - proxy.safeAreaInsets.bottom,
                            alignment: .bottom
                        )
                        .geometryGroup()
                        .offset(y: dragOffset)
                        .transition(.move(edge: .bottom))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .animation(reduceMotion ? nil : isPresented ? Motion.slow : Motion.base, value: isPresented)
        .onChange(of: isPresented) { _, isOpen in
            if isOpen { dragOffset = 0 }
        }
    }

    private func panel(hasBottomInset: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Capsule()
                    .fill(Color.lineNeutral)
                    .frame(width: Layout.sheetHandleWidth, height: Layout.sheetHandleHeight)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.x3)
                    .accessibilityHidden(true)

                Text(title)
                    .font_18_semibold(.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Spacing.x5)
                    .padding(.top, Spacing.x3)
                    .padding(.bottom, Spacing.x6)
                    .accessibilityAddTraits(.isHeader)
            }
            .contentShape(Rectangle())
            .gesture(dragGesture)

            ViewThatFits(in: .vertical) {
                bodyContent
                ScrollView {
                    bodyContent
                }
                .scrollBounceBehavior(.basedOnSize)
            }

            if Footer.self != EmptyView.self {
                footer()
                    .padding(.horizontal, Spacing.x5)
                    .padding(.top, Spacing.x4)
                    .padding(.bottom, hasBottomInset ? Spacing.bottomAction : Spacing.bottomActionFromEdge)
            }
        }
        .frame(maxWidth: .infinity)
        .background {
            UnevenRoundedRectangle(topLeadingRadius: Radius.sheet, topTrailingRadius: Radius.sheet)
                .fill(Color.surface)
                .padding(.bottom, -400)
                .ignoresSafeArea(edges: .bottom)
        }
        .accessibilityAddTraits(.isModal)
    }

    private var bodyContent: some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Spacing.x5)
            .padding(.bottom, Spacing.x6)
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard !isDismissDisabled else { return }
                dragOffset = max(0, value.translation.height)
            }
            .onEnded { value in
                if !isDismissDisabled, value.translation.height > 96 || value.predictedEndTranslation.height > 240 {
                    dismiss()
                } else {
                    withAnimation(reduceMotion ? nil : Motion.base) { dragOffset = 0 }
                }
            }
    }

    private func dismiss() {
        guard !isDismissDisabled else { return }
        Haptics.close()
        isPresented = false
    }
}

extension BottomSheet where Footer == EmptyView {
    init(
        isPresented: Binding<Bool>,
        title: String,
        isDismissDisabled: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(
            isPresented: isPresented,
            title: title,
            isDismissDisabled: isDismissDisabled,
            content: content,
            footer: { EmptyView() }
        )
    }
}

extension View {
    func bottomSheet<Content: View, Footer: View>(
        isPresented: Binding<Bool>,
        title: String,
        isDismissDisabled: Bool = false,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder footer: @escaping () -> Footer
    ) -> some View {
        overlay {
            BottomSheet(
                isPresented: isPresented,
                title: title,
                isDismissDisabled: isDismissDisabled,
                content: content,
                footer: footer
            )
        }
    }

    func bottomSheet<Content: View>(
        isPresented: Binding<Bool>,
        title: String,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        overlay {
            BottomSheet(isPresented: isPresented, title: title, content: content)
        }
    }
}

#Preview("본문") {
    @Previewable @State var isPresented = true

    Button("열기") { isPresented = true }
        .font_16_medium(.ink)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.background)
        .bottomSheet(isPresented: $isPresented, title: "글자 모양 읽는 법") {
            Text(String(repeating: "높게 말한 글자는 위로, 길게 늘인 음절은 가로로 길어져요.\n", count: 40))
                .font_14_regular(.textBody, lineHeight: .percent160)
        }
}

#Preview("확인") {
    @Previewable @State var isPresented = true

    Button("열기") { isPresented = true }
        .font_16_medium(.ink)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.background)
        .bottomSheet(isPresented: $isPresented, title: "모든 기록을 지울까요?") {
            Text("연습 기록과 녹음, 분석 결과가 모두 삭제돼요. 삭제한 내용은 되돌릴 수 없어요.")
                .font_16_regular(.textSecondary, lineHeight: .percent160)
        } footer: {
            VStack(spacing: Spacing.x1) {
                GreenButton("계속 쓸게요", showArrow: false) { isPresented = false }
                TextButton("지우기", variant: .destructive) { isPresented = false }
            }
        }
}
