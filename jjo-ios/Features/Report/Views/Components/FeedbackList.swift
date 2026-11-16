//
//  FeedbackList.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

struct FeedbackList: View {
    let items: [FeedbackItem]
    let playing: PlaybackRange?
    var onPlay: ((FeedbackItem) -> Void)?

    var body: some View {
        if items.isEmpty {
            Text("이번 연습에서는 고칠 점을 찾지 못했어요.\n지금처럼 연습해 보세요.")
                .font_15_medium(.textMuted, lineHeight: .percent150)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, Spacing.x10)
        } else {
            VStack(spacing: 0) {
                ForEach(items, id: \.rank) { item in
                    FeedbackRow(
                        item: item,
                        isFirst: item.rank == items.first?.rank,
                        isLast: item.rank == items.last?.rank,
                        isPlaying: playing == PlaybackRange(item),
                        onPlay: onPlay
                    )
                    .fadeUpOnAppear(delay: Double(item.rank - 1) * 0.08)
                }
            }
        }
    }
}

private struct FeedbackRow: View {
    let item: FeedbackItem
    let isFirst: Bool
    let isLast: Bool
    let isPlaying: Bool
    var onPlay: ((FeedbackItem) -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isOpen: Bool

    private static let bodyInset: CGFloat = 30

    init(item: FeedbackItem, isFirst: Bool, isLast: Bool, isPlaying: Bool, onPlay: ((FeedbackItem) -> Void)?) {
        self.item = item
        self.isFirst = isFirst
        self.isLast = isLast
        self.isPlaying = isPlaying
        self.onPlay = onPlay
        _isOpen = State(initialValue: item.rank == 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            heading

            if isOpen {
                detail
                    .transition(.opacity)
            }
        }
        .padding(.top, isFirst ? Spacing.x1 : Spacing.x6)
        .padding(.bottom, Spacing.x6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipped()
        .padding(.bottom, isLast ? 0 : 1)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle()
                    .fill(Color.lineZinc)
                    .frame(height: 1)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: toggle)
    }

    private var heading: some View {
        Button(action: toggle) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(String(format: "%02d", item.rank))
                    .font_16_semibold(isFirst ? .olive : .textFaint)
                    .monospacedDigit()
                    .frame(minWidth: 20, alignment: .leading)

                Text(item.title)
                    .font_17_semibold(.ink)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Icon(.iconChevronRight, size: IconSize.medium, color: .textIcon)
                    .rotationEffect(.degrees(isOpen ? -90 : 90))
                    .alignmentGuide(.firstTextBaseline) { $0[VerticalAlignment.center] + 6 }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityValue(isOpen ? "펼쳐짐" : "접힘")
    }

    private var detail: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("“\(item.quote)”")
                .font_16_medium(.ink)
                .padding(.top, 10)

            Text(item.body)
                .font_15_regular(.textMuted, lineHeight: .percent150)
                .padding(.top, Spacing.x3)

            playButton
                .frame(maxWidth: .infinity)
                .padding(.leading, -Self.bodyInset)
                .padding(.top, Spacing.x5)
                .padding(.bottom, 2)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.leading, Self.bodyInset)
    }

    private var playButton: some View {
        Button {
            Haptics.press()
            onPlay?(item)
        } label: {
            HStack(spacing: 10) {
                PlayMark(isPlaying: isPlaying)
                    .fill(Color.ink)
                    .frame(width: isPlaying ? 10 : 9, height: 10)
                Text(isPlaying ? "멈추기" : "해당 부분 듣기")
                    .font_14_medium(.ink)
            }
            .padding(.vertical, Spacing.x2)
            .padding(.horizontal, Spacing.x4)
            .background(Color.surfaceMuted, in: Capsule())
        }
        .buttonStyle(.pressable)
        .disabled(onPlay == nil)
        .opacity(onPlay == nil ? 0.45 : 1)
    }

    private func toggle() {
        withAnimation(reduceMotion ? nil : Motion.slow) { isOpen.toggle() }
    }
}

private struct PlayMark: Shape {
    let isPlaying: Bool

    nonisolated func path(in rect: CGRect) -> Path {
        guard !isPlaying else { return Path(rect) }
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    let items = [
        FeedbackItem(
            rank: 1, title: "문장 끝 내려서 맺기", quote: "금융규제 측면인데요",
            body: "‘인데요’에서 끝이 올라가 질문처럼 들렸어요. 마지막 글자를 낮게 내려 말해 보세요.",
            startMs: 0, endMs: 1000, startIdx: 0, endIdx: 9, kind: .endRise
        ),
        FeedbackItem(
            rank: 2, title: "근거 부분 천천히 말하기", quote: "신용카드 보유 수가 낮기도 했으며",
            body: "중국 사례를 설명하는 구절이 평소보다 빨랐어요.",
            startMs: 0, endMs: 1000, startIdx: 0, endIdx: 9, kind: .pace
        )
    ]

    ScrollView {
        FeedbackList(items: items, playing: PlaybackRange(items[0]), onPlay: { _ in })
            .padding(Spacing.screenHorizontal)
    }
    .background(Color.background)
}
