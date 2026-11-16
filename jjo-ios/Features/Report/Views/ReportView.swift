//
//  ReportView.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

struct ReportView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(NavigationManager.self) private var navigation
    @Environment(AppMenu.self) private var menu: AppMenu?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var viewModel: ReportViewModel

    private static let bottomActionHeight = Spacing.x8 + Layout.greenButtonHeight + Spacing.bottomAction

    init(practiceID: UUID, recordingID: UUID) {
        _viewModel = State(initialValue: ReportViewModel(practiceID: practiceID, recordingID: recordingID))
    }

    init(viewModel: ReportViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        GeometryReader { proxy in
            ScrollViewReader { scroll in
                ScrollView {
                    VStack(spacing: 0) {
                        HeaderView(leading: .back(goBack), isMenuOpen: menu?.isPresented ?? false, onMenu: menu?.toggle)
                        intro
                        content(scroll)
                            .id(viewModel.recordingID)
                    }
                    .frame(minHeight: max(0, proxy.size.height - Self.bottomActionHeight), alignment: .top)
                }
                .scrollBounceBehavior(.basedOnSize)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    ReportBottomAction(isDisabled: viewModel.practice == nil, action: recordAgain)
                }
            }
        }
        .background(Color.background.ignoresSafeArea())
        .overlay {
            if viewModel.showsAnalyzing {
                AnalyzingView(
                    isDone: viewModel.isAnalysisDone,
                    detail: environment.runner.stage?.message ?? "잠시만 기다려 주세요.",
                    onDone: { viewModel.celebrate() },
                    onBack: goBack
                )
                    .id(viewModel.recordingID)
            }
        }
        .bottomSheet(isPresented: $viewModel.isGuideOpen, title: "글자 모양 보는 법") {
            UtteranceGuide()
        } footer: {
            GreenButton("확인", showArrow: false) { viewModel.isGuideOpen = false }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task { viewModel.load(using: environment) }
        .task(id: viewModel.syncKey(revision: environment.store.revision)) { await viewModel.sync(using: environment) }
        .onDisappear { viewModel.player.stop() }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 14) {
            Group {
                if let title = viewModel.title {
                    Text(title)
                        .font_22_bold(.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityAddTraits(.isHeader)
                } else {
                    SkeletonBlock(widthRatio: 0.64, height: 22 * 1.3)
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)

            attemptTabs
        }
        .padding(.top, Spacing.x5)
        .padding(.bottom, Spacing.x2)
    }

    @ViewBuilder
    private var attemptTabs: some View {
        let attempts = viewModel.attempts
        if attempts.isEmpty {
            Color.clear.frame(height: 38)
        } else {
            AttemptTabs(
                attempts: attempts,
                currentID: viewModel.recordingID,
                detail: viewModel.durationLabel,
                onSelect: { viewModel.select($0, using: environment) },
                onAdd: viewModel.practice == nil ? nil : { recordAgain() }
            )
            .frame(minHeight: 38)
        }
    }

    @ViewBuilder
    private func content(_ scroll: ScrollViewProxy) -> some View {
        switch viewModel.phase {
        case .missing:
            ReportNotice(
                title: "결과를 불러오지 못했어요.",
                message: ReportCopy.recordingNotFound,
                actionTitle: "다시 불러오기"
            ) { viewModel.retry(using: environment) }
        case .failed(let code):
            ReportNotice(
                title: "분석하지 못했어요.",
                message: ReportCopy.failure(code),
                actionTitle: "다시 분석하기"
            ) { viewModel.retry(using: environment) }
        case .result:
            result(scroll)
        }
    }

    private func result(_ scroll: ScrollViewProxy) -> some View {
        VStack(spacing: 0) {
            headline
            ReportTabBar(selection: viewModel.tab) { viewModel.setTab($0) }

            Group {
                switch viewModel.tab {
                case .summary: summary
                case .detail: detail(scroll)
                }
            }
            .padding(.top, Spacing.x5)
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.bottom, Spacing.x8 * 2)
        }
    }

    @ViewBuilder
    private var headline: some View {
        if let summary = viewModel.content?.overview.summary {
            VStack(alignment: .leading, spacing: Spacing.x1) {
                Text(summary.headline)
                    .font_22_regular(.textBody)
                Text(summary.footer)
                    .font_22_bold(.ink)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, Spacing.x6)
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.bottom, Spacing.x5)
            .fadeUpOnAppear()
            .accessibilityElement(children: .combine)
        } else {
            VStack(alignment: .leading, spacing: Spacing.x1) {
                SkeletonBlock(widthRatio: 0.62, height: 22 * 1.3)
                SkeletonBlock(widthRatio: 0.88, height: 22 * 1.3)
            }
            .padding(.top, Spacing.x6)
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.bottom, Spacing.x5)
        }
    }

    @ViewBuilder
    private var summary: some View {
        if let content = viewModel.content {
            SummaryPanel(
                content: content,
                playing: viewModel.player.playing,
                onPlay: viewModel.player.isAvailable ? { viewModel.play($0) } : nil,
                onFocusPace: { viewModel.focus($0) }
            )
        } else {
            Color.clear.frame(height: 240)
        }
    }

    @ViewBuilder
    private func detail(_ scroll: ScrollViewProxy) -> some View {
        if let content = viewModel.content {
            VStack(alignment: .leading, spacing: Spacing.x5) {
                ForEach(content.warnings, id: \.self) { warning in
                    ReportWarningBanner(warning: warning)
                        .padding(.bottom, Spacing.x3)
                }

                PaceToolbar(
                    speed: content.overview.speed,
                    focusPace: viewModel.focusPace,
                    onToggle: { viewModel.togglePace($0) },
                    onGuide: { viewModel.isGuideOpen = true }
                )
                .padding(.bottom, Spacing.x1)

                UtteranceTextView(
                    content: content,
                    playing: viewModel.player.playing,
                    currentChar: viewModel.player.position,
                    focusPace: viewModel.focusPace,
                    introStart: viewModel.detailShownAt,
                    scrollProxy: scroll,
                    onSelectSegment: viewModel.player.isAvailable ? { viewModel.playSegment($0) } : nil
                )
            }
        } else {
            Color.clear.frame(height: 240)
        }
    }

    private func goBack() {
        navigation.popToRoot()
    }

    private func recordAgain() {
        viewModel.player.stop()
        navigation.push(.record(practiceID: viewModel.practiceID))
    }
}
