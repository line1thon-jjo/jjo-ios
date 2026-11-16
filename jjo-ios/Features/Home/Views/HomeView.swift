//
//  HomeView.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

struct HomeView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(NavigationManager.self) private var navigation
    @Environment(AppMenu.self) private var menu
    @Environment(ScriptReveal.self) private var reveal
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var viewModel = HomeViewModel()
    @State private var addButtonCenter: CGPoint = .zero

    private static let skeletonRows = 4

    var body: some View {
        VStack(spacing: 0) {
            HeaderView(isMenuOpen: menu.isPresented, onMenu: menu.toggle)

            if let entries = viewModel.entries, entries.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    hello
                    NoticeView(title: "아직 연습이 없어요.", message: "오른쪽 아래 + 버튼으로 첫 대본을 넣어 보세요.")
                }
                .padding(.top, Spacing.x2)
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.bottom, 120)
            } else {
                list
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.background.ignoresSafeArea())
        .overlay(alignment: .bottomTrailing) {
            AddButton {
                reveal.open(from: addButtonCenter, reduceMotion: reduceMotion, navigation: navigation)
            }
            .onGeometryChange(for: CGPoint.self) { proxy in
                let frame = proxy.frame(in: .global)
                return CGPoint(x: frame.midX, y: frame.midY)
            } action: { addButtonCenter = $0 }
            .padding(.trailing, Spacing.screenHorizontal)
            .padding(.bottom, 30)
        }
        .onChange(of: environment.store.revision, initial: true) {
            viewModel.load(from: environment.store)
        }
        .onAppear {
            viewModel.selection = .automatic
            Haptics.prepare()
        }
    }

    private var hello: some View {
        VStack(alignment: .leading, spacing: Spacing.x1) {
            Text("\(Greeting.text()),")
                .font_26_regular(.textSecondary)
            Text(Greeting.closing)
                .font_26_bold(.ink)
        }
        .padding(.top, 28)
        .padding(.bottom, 36)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private var list: some View {
        ScrollViewReader { scroll in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    hello

                    if let entries = viewModel.entries {
                        VStack(spacing: Spacing.x1) {
                            ForEach(entries) { entry in
                                row(entry, scroll: scroll)
                                    .id(entry.id)
                            }
                        }
                        .fadeUpOnAppear(delay: 0.08)
                    } else {
                        skeleton
                    }
                }
                .padding(.top, Spacing.x2)
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.bottom, 120)
            }
        }
    }

    private var skeleton: some View {
        VStack(spacing: Spacing.x1) {
            ForEach(0..<Self.skeletonRows, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 10) {
                    SkeletonBlock(widthRatio: 0.56, height: 22)
                    SkeletonBlock(widthRatio: 0.32)
                }
                .padding(.vertical, 22)
            }
        }
        .accessibilityLabel("연습 목록을 불러오는 중")
    }

    private func row(_ entry: HomeEntry, scroll: ScrollViewProxy) -> some View {
        PracticeRow(
            entry: entry,
            isOpen: entry.id == viewModel.openID,
            loadSummary: { await viewModel.summary(for: entry, in: environment.store) },
            onToggle: {
                Haptics.select()
                if viewModel.toggle(entry.id) { scrollIntoView(entry.id, with: scroll) }
            },
            onRecord: { navigation.push(.record(practiceID: entry.id)) },
            onOpenReport: {
                guard let latestID = entry.latestID else { return }
                navigation.push(.report(practiceID: entry.id, recordingID: latestID))
            }
        )
    }

    private func scrollIntoView(_ id: UUID, with scroll: ScrollViewProxy) {
        Task {
            try? await Task.sleep(for: .seconds(Motion.Duration.slow))
            withAnimation(reduceMotion ? nil : Motion.slow) { scroll.scrollTo(id) }
        }
    }
}

#Preview {
    HomeView()
        .environment(AppEnvironment.preview())
        .environment(NavigationManager())
        .environment(AppMenu())
        .environment(ScriptReveal())
}
