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

    var body: some View {
        ZStack {
            if environment.settings.onboardingCompleted {
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
            environment.runner.resumeInterrupted()
            try? await Transcriber.prepare()
        }
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
