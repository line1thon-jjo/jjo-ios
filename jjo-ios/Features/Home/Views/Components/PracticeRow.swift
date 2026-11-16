//
//  PracticeRow.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

struct PracticeRow: View {
    let entry: HomeEntry
    let isOpen: Bool
    let loadSummary: () async -> PracticeSummary?
    let onToggle: () -> Void
    let onRecord: () -> Void
    let onOpenReport: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hasOpened = false
    @State private var contentHeight: CGFloat = 0

    private static let clipHeight: CGFloat = 248

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            heading

            detail
                .frame(height: isOpen ? nil : 0, alignment: .top)
                .clipped()
                .opacity(isOpen ? 1 : 0)
                .allowsHitTesting(isOpen)
                .accessibilityHidden(!isOpen)
        }
        .padding(.vertical, 22)
        .contentShape(Rectangle())
        .onTapGesture(perform: onToggle)
        .animation(reduceMotion ? nil : Motion.slow, value: isOpen)
        .onChange(of: isOpen, initial: true) {
            if isOpen { hasOpened = true }
        }
    }

    private var heading: some View {
        VStack(alignment: .leading, spacing: Spacing.x2) {
            HStack(spacing: Spacing.x3) {
                Text(entry.title)
                    .font_18_semibold(.ink)
                    .lineLimit(1)
                    .background(alignment: .leading) { mark }

                Spacer(minLength: 0)

                Icon(.iconChevronRight, size: IconSize.medium, color: .textIcon)
                    .opacity(0.5)
                    .rotationEffect(.degrees(isOpen ? -90 : 90))
            }

            HStack(spacing: 10) {
                if entry.attemptCount > 0 {
                    Text("\(entry.attemptCount)회차")
                        .font_14_medium(.textSecondary)
                }
                Text(RelativeTime.text(for: entry.activeAt))
                    .font_14_medium(.textSubtle)

                if entry.latestID == nil {
                    Spacer(minLength: 0)
                    Text("녹음 전")
                        .font_14_medium(.textFaint)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(isOpen ? "펼침" : "접힘")
        .accessibilityAction(.default, onToggle)
    }

    private var mark: some View {
        GeometryReader { proxy in
            Rectangle()
                .fill(Color.lime)
                .frame(width: proxy.size.width * (isOpen ? 1 : 0), height: proxy.size.height * 0.42)
                .offset(y: proxy.size.height * 0.51)
                .animation(reduceMotion ? nil : Motion.standard(0.42), value: isOpen)
        }
    }

    private var detail: some View {
        VStack(spacing: 0) {
            clip

            Group {
                if entry.latestID == nil {
                    GreenButton("녹음 시작하기", action: onRecord)
                } else {
                    GreenButton("이어서 연습하기", action: onOpenReport)
                }
            }
            .padding(.top, Spacing.x5)
        }
    }

    private var clip: some View {
        let isOverflowing = contentHeight > Self.clipHeight + 1

        return summary
            .fixedSize(horizontal: false, vertical: true)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
            .frame(maxHeight: Self.clipHeight, alignment: .top)
            .clipped()
            .mask {
                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0),
                        .init(color: .black, location: isOverflowing ? 0.64 : 1),
                        .init(color: isOverflowing ? .clear : .black, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
    }

    @ViewBuilder
    private var summary: some View {
        if !hasOpened {
            Color.clear
                .frame(height: 0)
        } else if entry.latestCompletedID != nil {
            PracticeSummaryView(entry: entry, load: loadSummary)
        } else {
            PracticeScriptExcerpt(script: entry.script)
        }
    }
}
