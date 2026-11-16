//
//  ScriptView.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI
import UniformTypeIdentifiers

struct ScriptView: View {
    let viewModel: ScriptViewModel
    var isSnapshot = false

    @Environment(AppEnvironment.self) private var environment
    @Environment(NavigationManager.self) private var navigation
    @Environment(AppMenu.self) private var menu
    @Environment(ScriptReveal.self) private var reveal
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @FocusState private var isEditorFocused: Bool
    @State private var isImporterPresented = false

    private static let compactHeight: CGFloat = 700

    var body: some View {
        GeometryReader { proxy in
            let isCompact = proxy.size.height + proxy.safeAreaInsets.top <= Self.compactHeight

            VStack(spacing: 0) {
                HeaderView(leading: .back(back), isMenuOpen: menu.isPresented, onMenu: openMenu)

                VStack(alignment: .leading, spacing: 0) {
                    Text(ScriptMessage.description)
                        .pretendard(.regular, 13, .textBody, lineHeight: .percent160, tracking: false)
                        .padding(.bottom, 13)

                    PillButton("파일 업로드", icon: .iconUpload, variant: .wide) {
                        isEditorFocused = false
                        isImporterPresented = true
                    }
                    .padding(.bottom, isCompact ? Spacing.x4 : Spacing.x6)

                    ScriptEditor(
                        text: Binding(get: { viewModel.script }, set: { viewModel.update($0) }),
                        count: viewModel.count,
                        isSnapshot: isSnapshot,
                        isFocused: $isEditorFocused
                    )

                    GreenButton(
                        viewModel.isCreating ? "녹음 준비 중" : "녹음하기",
                        isDisabled: viewModel.isCreating,
                        action: submit
                    )
                    .padding(.top, isCompact ? Spacing.x4 : 35)
                }
                .padding(.top, isCompact ? Spacing.x5 : 50)
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.bottom, bottomPadding(isCompact: isCompact, safeBottom: proxy.safeAreaInsets.bottom))
            }
            .animation(reduceMotion ? nil : Motion.base, value: isCompact)
        }
        .background {
            Color.background
                .ignoresSafeArea()
                .onTapGesture { isEditorFocused = false }
        }
        .onDisappear {
            if !isSnapshot { viewModel.cancelCreation() }
        }
        .fileImporter(isPresented: $isImporterPresented, allowedContentTypes: [.plainText]) { result in
            switch result {
            case .success(let url):
                Task { await viewModel.importFile(at: url) }
            case .failure:
                viewModel.alertMessage = ScriptMessage.unreadable
            }
        }
        .alert(
            viewModel.alertMessage ?? "",
            isPresented: Binding(
                get: { viewModel.alertMessage != nil },
                set: { if !$0 { viewModel.alertMessage = nil } }
            )
        ) {
            Button("확인", role: .cancel) {}
        }
    }

    private func bottomPadding(isCompact: Bool, safeBottom: CGFloat) -> CGFloat {
        isCompact || safeBottom > 0 ? Spacing.bottomAction : Spacing.bottomActionFromEdge
    }

    private func back() {
        isEditorFocused = false
        reveal.close(reduceMotion: reduceMotion, navigation: navigation)
    }

    private func openMenu() {
        isEditorFocused = false
        menu.toggle()
    }

    private func submit() {
        isEditorFocused = false
        Task {
            guard let practiceID = await viewModel.create(in: environment.store) else {
                if viewModel.alertMessage != nil { Haptics.warning() }
                return
            }
            guard navigation.path.last == .script else { return }
            // 웹처럼 화면 전환 없이 버튼이 녹음 바로 이어지게 하고, 뒤로 가면 빈 대본 대신 홈으로 돌아간다
            navigation.instantly { $0.replaceTop(with: .record(practiceID: practiceID)) }
        }
    }
}

#Preview {
    ScriptView(viewModel: ScriptViewModel())
        .environment(AppEnvironment.preview())
        .environment(NavigationManager())
        .environment(AppMenu())
        .environment(ScriptReveal())
}
