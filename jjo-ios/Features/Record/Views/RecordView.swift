//
//  RecordView.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI
import UIKit

struct RecordView: View {
    let practiceID: UUID

    @Environment(AppEnvironment.self) private var environment
    @Environment(NavigationManager.self) private var navigation
    @Environment(AppMenu.self) private var menu
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    @State private var recorder = AudioRecorder()
    @State private var title = ""
    @State private var script = ""
    @State private var hasMorphed = false
    @State private var isSubmitting = false
    @State private var isUnsupported = false

    private static let barHeight: CGFloat = 76

    private var failure: String? {
        if isUnsupported { return RecordMessage.unsupported }
        return recorder.errorMessage ?? (recorder.isTooShort ? RecordMessage.tooShort : nil)
    }

    private var notice: String? {
        recorder.status == .done && recorder.reachedLimit ? RecordMessage.reachedLimit : nil
    }

    var body: some View {
        VStack(spacing: 0) {
            HeaderView(leading: .back(back), isMenuOpen: menu.isPresented, onMenu: menu.toggle)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(title)
                        .font_16_bold(.pureBlack)
                        .padding(.vertical, Spacing.x2)
                        .accessibilityAddTraits(.isHeader)

                    Text(script)
                        .font_14_regular(.textBody, lineHeight: .percent160)
                        .padding(.top, Spacing.x3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.bottom, Spacing.x6)
            }

            bottom
        }
        .background(Color.background.ignoresSafeArea())
        .onAppear(perform: prepare)
        .onDisappear {
            recorder.reset()
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onChange(of: recorder.status) { _, status in
            // 대본을 읽는 동안 화면이 꺼지면 녹음이 끊기므로 녹음 중에는 자동 잠금을 막는다
            UIApplication.shared.isIdleTimerDisabled = status == .recording || status == .paused
            announce(status)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { recorder.pause() }
        }
        .onChange(of: failure) { _, message in
            if message != nil { Haptics.warning() }
        }
    }

    private var bottom: some View {
        VStack(spacing: Spacing.x2) {
            if let failure {
                Text(failure)
                    .pretendard(.regular, 13, .recordRed, lineHeight: .percent130, tracking: false)
            } else if let notice {
                Text(notice)
                    .pretendard(.regular, 13, .textMuted, lineHeight: .percent130, tracking: false)
            }

            ZStack {
                HStack {
                    Text("녹음하기")
                        .pretendard(.bold, 17, .pureBlack, lineHeight: .natural, tracking: false)
                    Spacer(minLength: 0)
                    Icon(.iconArrowRight, size: IconSize.medium, color: .pureBlack)
                }
                .padding(.horizontal, Spacing.x5)
                .opacity(hasMorphed ? 0 : 1)
                .animation(reduceMotion ? nil : Motion.standard(0.16), value: hasMorphed)
                .accessibilityHidden(true)

                RecordBar(
                    status: recorder.status,
                    seconds: recorder.seconds,
                    isBusy: isSubmitting,
                    canConfirm: !recorder.isTooShort,
                    onStart: start,
                    onPause: pause,
                    onResume: resume,
                    onStop: stop,
                    onRetry: retry,
                    onConfirm: confirm
                )
                .opacity(hasMorphed ? 1 : 0)
                .animation(reduceMotion ? nil : Motion.standard(0.24).delay(0.28), value: hasMorphed)
            }
            .frame(maxWidth: .infinity)
            .frame(height: hasMorphed ? Self.barHeight : Layout.greenButtonHeight)
            .background(hasMorphed ? Color.pureBlack : Color.lime)
            .clipped()
            .animation(reduceMotion ? nil : Motion.standard(0.48), value: hasMorphed)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, Spacing.screenHorizontal)
        .padding(.bottom, Spacing.bottomAction)
    }

    private func prepare() {
        guard let practice = environment.store.practice(id: practiceID) else {
            navigation.pop()
            return
        }
        title = practice.title
        script = practice.script
        hasMorphed = true
    }

    private func back() {
        guard !isSubmitting else { return }
        recorder.reset()
        navigation.pop()
    }

    private func start() {
        Haptics.open()
        Task {
            isUnsupported = await !Transcriber.isSupported()
            guard !isUnsupported else { return }
            await recorder.start()
        }
    }

    private func pause() {
        Haptics.select()
        recorder.pause()
    }

    private func resume() {
        Haptics.select()
        recorder.resume()
    }

    private func stop() {
        Haptics.commit()
        recorder.stop()
    }

    private func retry() {
        Haptics.press()
        recorder.reset()
    }

    private func confirm() {
        guard !isSubmitting, !recorder.isTooShort,
              let practice = environment.store.practice(id: practiceID),
              let file = recorder.takeFile()
        else { return }

        isSubmitting = true
        let recording = environment.store.addRecording(to: practice, fileURL: file.url, durationMs: file.durationMs)
        environment.runner.start(recordingID: recording.id)
        Haptics.success()
        navigation.replaceTop(with: .report(practiceID: practiceID, recordingID: recording.id))
    }

    private func announce(_ status: AudioRecorder.Status) {
        let message: String? = switch status {
        case .recording: "녹음 중"
        case .paused: "일시정지"
        case .done: "녹음 완료, \(RecordTime.spoken(recorder.seconds))"
        case .idle: nil
        }
        if let message {
            AccessibilityNotification.Announcement(message).post()
        }
    }
}
