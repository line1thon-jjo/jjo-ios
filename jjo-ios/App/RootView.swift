//
//  RootView.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

struct RootView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var navigation = NavigationManager()
    @State private var menu = AppMenu()
    @State private var reveal = ScriptReveal()
    @State private var isSplashVisible = true
    @State private var isSupported = true

    var body: some View {
        ZStack {
            if !isSupported {
                NoticeView(title: "이 기기에서는 jjo를 쓸 수 없어요.", message: "한국어 음성 인식을 지원하는 기기가 필요해요.")
                    .padding(.horizontal, Spacing.screenHorizontal)
                    .background(Color.background.ignoresSafeArea())
            } else if environment.settings.onboardingCompleted {
                main
                    .transition(.opacity)
            } else {
                OnboardingView {
                    environment.settings.onboardingCompleted = true
                }
                .transition(.opacity)
            }

            if menu.isReplayingOnboarding {
                OnboardingView(isReplay: true) {
                    menu.isReplayingOnboarding = false
                }
                .transition(.opacity)
                .zIndex(1)
            }

            if isSplashVisible {
                AppSplash { isSplashVisible = false }
                    .zIndex(2)
            }
        }
        .animation(reduceMotion ? nil : Motion.slow, value: environment.settings.onboardingCompleted)
        .animation(reduceMotion ? nil : Motion.slow, value: menu.isReplayingOnboarding)
        .environment(navigation)
        .environment(menu)
        .environment(reveal)
        .task {
            isSupported = await Self.supportsAnalysis()
            guard isSupported else { return }
            environment.runner.resumeInterrupted()
            try? await Transcriber.prepare()
        }
    }

    private static func supportsAnalysis() async -> Bool {
        // 시뮬레이터에는 한국어 음성 인식 모델이 없어서, 화면 확인까지 막히지 않도록 통과시킨다
        #if targetEnvironment(simulator)
        true
        #else
        await Transcriber.isSupported()
        #endif
    }

    private var main: some View {
        @Bindable var navigation = navigation

        return NavigationStack(path: $navigation.path) {
            HomeView()
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: Route.self) { route in
                    destination(for: route)
                        .toolbar(.hidden, for: .navigationBar)
                        .interactivePopGestureEnabled()
                }
        }
        .overlay { ScriptRevealOverlay() }
        .appMenu()
    }

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .script:
            ScriptView(viewModel: reveal.viewModel)
        case .record(let practiceID):
            RecordView(practiceID: practiceID)
        case .report(let practiceID, let recordingID):
            ReportView(practiceID: practiceID, recordingID: recordingID)
        }
    }
}

#Preview {
    RootView()
        .environment(AppEnvironment.preview())
}
