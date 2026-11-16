//
//  PracticeSummaryView.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

struct PracticeSummaryView: View {
    let entry: HomeEntry
    let load: () async -> PracticeSummary?

    private enum Phase: Equatable {
        case loading
        case loaded(PracticeSummary)
        case unavailable
    }

    @State private var phase: Phase = .loading

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.x5) {
            switch phase {
            case .loading:
                SkeletonBlock(widthRatio: 0.64, height: 22)
                SkeletonBlock(widthRatio: 0.88, height: 22)
                SkeletonBlock(height: 96)
            case .loaded(let summary):
                VStack(alignment: .leading, spacing: 2) {
                    Text(summary.summary.headline)
                        .font_17_regular(.textBody)
                    Text(summary.summary.footer)
                        .font_17_bold(.ink)
                }
                .accessibilityElement(children: .combine)

                HabitRowsView(rows: summary.rows)
            case .unavailable:
                PracticeScriptExcerpt(script: entry.script)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, phase == .unavailable ? 0 : 28)
        .task(id: [entry.latestCompletedID, entry.previousCompletedID]) {
            phase = await load().map(Phase.loaded) ?? .unavailable
        }
    }
}

struct PracticeScriptExcerpt: View {
    let script: String

    var body: some View {
        Text(script)
            .font_16_regular(.textSecondary, lineHeight: .percent160)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 28)
    }
}
