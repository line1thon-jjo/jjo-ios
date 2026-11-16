//
//  AttemptTabs.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

struct AttemptTabs: View {
    let attempts: [ReportAttempt<UUID>]
    let currentID: UUID
    let detail: String?
    let onSelect: (UUID) -> Void
    var onAdd: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack(spacing: Spacing.x2) {
                    ForEach(attempts, id: \.recordingId) { attempt in
                        tab(attempt)
                            .id(attempt.recordingId)
                    }
                    if let onAdd {
                        addButton(onAdd)
                    }
                }
                .padding(.vertical, 2)
                .padding(.horizontal, Spacing.screenHorizontal)
                .animation(reduceMotion ? nil : Motion.slow, value: currentID)
            }
            .scrollIndicators(.hidden)
            .onChange(of: currentID, initial: true) {
                withAnimation(reduceMotion ? nil : .smooth) { proxy.scrollTo(currentID) }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("연습 회차")
    }

    private func tab(_ attempt: ReportAttempt<UUID>) -> some View {
        let isCurrent = attempt.recordingId == currentID
        let status = attempt.status.flatMap { $0 == .completed ? nil : $0 }

        return Button {
            guard !isCurrent else { return }
            Haptics.select()
            onSelect(attempt.recordingId)
        } label: {
            HStack(spacing: 6) {
                Text("\(attempt.attemptNo)회차")
                    .font_14_semibold(isCurrent ? .pureWhite : .textBody)
                if isCurrent, let detail {
                    Text(detail)
                        .font_14_medium(.lime)
                        .transition(.opacity)
                }
                if let status {
                    AttemptStatusDot(status: status)
                }
            }
            .lineLimit(1)
            .padding(.horizontal, 14)
            .frame(height: 34)
            .background(isCurrent ? Color.ink : Color.surface, in: Capsule())
            .overlay(Capsule().strokeBorder(isCurrent ? Color.ink : Color.lineZinc, lineWidth: 1))
        }
        .buttonStyle(.pressable)
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
    }

    private func addButton(_ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Icon(.iconPlus, size: IconSize.tiny, color: .pureBlack)
                .frame(width: 34, height: 34)
                .overlay(Circle().strokeBorder(Color.lineDashed, style: StrokeStyle(lineWidth: 1, dash: [3, 3])))
        }
        .buttonStyle(.pressable)
        .accessibilityLabel("다시 녹음하기")
    }
}

private struct AttemptStatusDot: View {
    let status: ReportStatus

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPulsing = false

    var body: some View {
        Circle()
            .fill(status == .failed ? Color.danger : Color.limeStatus)
            .frame(width: 6, height: 6)
            .opacity(status.isInProgress && !isPulsing && !reduceMotion ? 0.3 : 1)
            .onAppear {
                guard status.isInProgress, !reduceMotion else { return }
                withAnimation(Motion.standard(1.2).repeatForever(autoreverses: true)) { isPulsing = true }
            }
            .accessibilityLabel(ReportCopy.statusLabel(status))
    }
}

#Preview {
    let ids = [UUID(), UUID(), UUID()]

    AttemptTabs(
        attempts: [
            ReportAttempt(recordingId: ids[0], attemptNo: 1, recordedAt: .now, status: .completed),
            ReportAttempt(recordingId: ids[1], attemptNo: 2, recordedAt: .now, status: .failed),
            ReportAttempt(recordingId: ids[2], attemptNo: 3, recordedAt: .now, status: .analyzing)
        ],
        currentID: ids[0],
        detail: "53초",
        onSelect: { _ in },
        onAdd: {}
    )
    .background(Color.background)
}
