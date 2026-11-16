//
//  ReportWarningBanner.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

struct ReportWarningBanner: View {
    let warning: ReportWarning

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Text("!")
                .pretendard(.bold, 11, .pureWhite, lineHeight: .natural, tracking: false)
                .frame(width: 16, height: 16)
                .background(Color.textMuted, in: Circle())
                .padding(.top, 2)
                .accessibilityHidden(true)

            Text(ReportCopy.warning(warning))
                .font_14_regular(.textBody, lineHeight: .percent150)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, Spacing.x2)
        .padding(.horizontal, Spacing.x3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surfaceMuted, in: RoundedRectangle(cornerRadius: Radius.notice))
    }
}

#Preview {
    VStack(spacing: Spacing.x3) {
        ForEach(ReportWarning.allCases, id: \.self) { ReportWarningBanner(warning: $0) }
    }
    .padding(Spacing.screenHorizontal)
    .background(Color.background)
}
