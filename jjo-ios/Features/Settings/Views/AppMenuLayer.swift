//
//  AppMenuLayer.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

struct AppMenuLayer: ViewModifier {
    @Environment(AppEnvironment.self) private var environment
    @Environment(NavigationManager.self) private var navigation
    @Environment(AppMenu.self) private var menu
    @Environment(\.openURL) private var openURL

    func body(content: Content) -> some View {
        @Bindable var menu = menu

        content
            .menuPanel(
                isPresented: $menu.isPresented,
                subtitle: "모든 기록은 이 기기에만 저장돼요",
                items: [
                    MenuPanelItem(title: "사용법 다시 보기") { menu.replayOnboarding() },
                    MenuPanelItem(title: "문의하기") { openURL(AppLinks.support) },
                    MenuPanelItem(title: "개인정보 처리방침") { openURL(AppLinks.privacy) }
                ]
            ) {
                VStack(alignment: .leading, spacing: Spacing.x1) {
                    TextButton("모든 데이터 삭제", variant: .underline) {
                        menu.isResetSheetPresented = true
                    }
                    Text(AppMenu.versionText)
                        .font_13_regular(.textFaint)
                }
            }
            .bottomSheet(isPresented: $menu.isResetSheetPresented, title: "모든 데이터를 삭제할까요?") {
                Text("연습 기록과 녹음, 분석 결과가 모두 삭제돼요. 삭제한 내용은 되돌릴 수 없어요.")
                    .font_16_regular(.textSecondary, lineHeight: .percent160)
            } footer: {
                VStack(spacing: Spacing.x1) {
                    GreenButton("계속 쓸게요", showArrow: false) { menu.isResetSheetPresented = false }
                    TextButton("삭제하기", variant: .destructive, action: deleteAll)
                }
            }
    }

    private func deleteAll() {
        Haptics.commit()
        menu.dismissAll()
        navigation.popToRoot()
        environment.store.deleteAll()
    }
}

extension View {
    func appMenu() -> some View {
        modifier(AppMenuLayer())
    }
}
