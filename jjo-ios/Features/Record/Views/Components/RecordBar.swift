//
//  RecordBar.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

struct RecordBar: View {
    let status: AudioRecorder.Status
    let seconds: Int
    var isBusy = false
    var canConfirm = true
    let onStart: () -> Void
    let onPause: () -> Void
    let onResume: () -> Void
    let onStop: () -> Void
    let onRetry: () -> Void
    let onConfirm: () -> Void

    private var isRecording: Bool { status == .recording }

    var body: some View {
        HStack {
            HStack(spacing: Spacing.x2) {
                Circle()
                    .fill(isRecording ? Color.recordRed : Color.recordIdleDot)
                    .frame(width: 8, height: 8)

                Text(RecordTime.clock(seconds))
                    .pretendard(
                        .semiBold, 17, isRecording ? .pureWhite : .line, lineHeight: .points(20), tracking: false
                    )
                    .monospacedDigit()
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(statusLabel)
            .accessibilityValue(RecordTime.spoken(seconds))
            .accessibilityAddTraits(.updatesFrequently)

            Spacer(minLength: 0)

            HStack(spacing: 14) {
                actions
            }
        }
        .padding(.leading, Spacing.x5)
        .padding(.trailing, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var statusLabel: String {
        switch status {
        case .idle: "녹음 대기"
        case .recording: "녹음 중"
        case .paused: "일시정지"
        case .done: "녹음 완료"
        }
    }

    @ViewBuilder
    private var actions: some View {
        switch status {
        case .idle:
            RecordCircleButton(tone: .main, title: "녹음 시작", action: onStart) {
                Icon(.iconMic, size: 23, color: .pureBlack)
            }
        case .recording:
            RecordCircleButton(tone: .dark, title: "일시정지", action: onPause) { RecordGlyph.pause }
            RecordCircleButton(tone: .red, title: "녹음 종료", action: onStop) { RecordGlyph.stop }
        case .paused:
            RecordCircleButton(tone: .dark, title: "이어서 녹음", action: onResume) { RecordGlyph.play }
            RecordCircleButton(tone: .red, title: "녹음 종료", action: onStop) { RecordGlyph.stop }
        case .done:
            RecordCircleButton(tone: .dark, title: "다시 녹음", isDisabled: isBusy, action: onRetry) {
                Icon(.iconRetry, size: IconSize.medium, color: .pureWhite)
            }
            RecordCircleButton(tone: .main, title: "녹음 완료", isDisabled: isBusy || !canConfirm, action: onConfirm) {
                RecordGlyph.check
            }
        }
    }
}

#Preview {
    VStack(spacing: Spacing.x3) {
        ForEach([AudioRecorder.Status.idle, .recording, .paused, .done], id: \.self) { status in
            RecordBar(
                status: status, seconds: 65,
                onStart: {}, onPause: {}, onResume: {}, onStop: {}, onRetry: {}, onConfirm: {}
            )
            .frame(height: 76)
            .background(Color.pureBlack)
        }
    }
    .padding(Spacing.screenHorizontal)
}
