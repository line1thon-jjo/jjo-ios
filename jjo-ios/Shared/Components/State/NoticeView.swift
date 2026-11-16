//
//  NoticeView.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

struct NoticeView: View {
    let title: String
    var message: String?
    var messageColor: Color = .textZinc
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: Spacing.x2) {
            Text(title)
                .font_16_semibold(.ink)

            if let message {
                Text(message)
                    .font_14_regular(messageColor)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let actionTitle, let action {
                PillButton(actionTitle, action: action)
                    .padding(.top, Spacing.x3)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("빈 상태") {
    NoticeView(title: "아직 연습이 없어요.", message: "오른쪽 아래 + 버튼으로 첫 대본을 넣어 보세요.")
        .background(Color.background)
}

#Preview("오류") {
    NoticeView(
        title: "연습 목록을 불러오지 못했어요.",
        message: "문제가 생겼어요. 잠시 후 다시 시도해 주세요.",
        actionTitle: "다시 시도"
    ) {}
    .background(Color.background)
}
