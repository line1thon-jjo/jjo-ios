//
//  SummaryPanel.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

struct SummaryPanel: View {
    let content: ReportContent
    let playing: PlaybackRange?
    var onPlay: ((FeedbackItem) -> Void)?
    let onFocusPace: (UtteranceAnalysis.PaceLabel) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.x10) {
            VStack(alignment: .leading, spacing: 0) {
                heading("연습 포인트")
                FeedbackList(items: content.feedback.items, playing: playing, onPlay: onPlay)
            }

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    heading("말하기 습관")
                    Spacer(minLength: Spacing.x3)
                    if content.hasPrevious {
                        Text("지난 연습 대비")
                            .font_14_regular(.textFaint)
                    }
                }
                HabitRowsView(rows: content.habitRows, onFocusPace: onFocusPace)
            }
        }
    }

    private func heading(_ text: String) -> some View {
        Text(text)
            .font_17_semibold(.ink)
            .padding(.bottom, Spacing.x3)
            .accessibilityAddTraits(.isHeader)
    }
}
