//
//  ReportNotice.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

struct ReportNotice: View {
    let title: String
    let message: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: Spacing.x2) {
            Text(title)
                .font_18_semibold(.ink)
            Text(message)
                .font_14_regular(.textBody)
                .fixedSize(horizontal: false, vertical: true)
            PillButton(actionTitle, action: action)
                .padding(.top, Spacing.x3)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, Spacing.screenHorizontal)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ReportNotice(
        title: "분석하지 못했어요.",
        message: ReportCopy.failure(.noSpeech),
        actionTitle: "다시 분석하기"
    ) {}
    .background(Color.background)
}
