//
//  MenuPanel.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

struct MenuPanel<Footer: View>: View {
    @Binding var isPresented: Bool
    let title: String
    var subtitle: String?
    let items: [MenuPanelItem]
    @ViewBuilder let footer: () -> Footer

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            if isPresented {
                MenuPanelContent(
                    title: title,
                    subtitle: subtitle,
                    items: items,
                    onClose: close,
                    footer: footer
                )
                .transition(.opacity)
            }
        }
        .animation(reduceMotion ? nil : isPresented ? Motion.slow : Motion.base, value: isPresented)
    }

    private func close() {
        Haptics.close()
        isPresented = false
    }
}

extension MenuPanel where Footer == EmptyView {
    init(isPresented: Binding<Bool>, title: String, subtitle: String? = nil, items: [MenuPanelItem]) {
        self.init(isPresented: isPresented, title: title, subtitle: subtitle, items: items) { EmptyView() }
    }
}

private struct MenuPanelContent<Footer: View>: View {
    let title: String
    let subtitle: String?
    let items: [MenuPanelItem]
    let onClose: () -> Void
    @ViewBuilder let footer: () -> Footer

    @State private var hasAppeared = false

    var body: some View {
        GeometryReader { proxy in
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Spacer(minLength: 0)
                    BurgerButton(isOpen: hasAppeared, action: onClose)
                }
                .frame(height: Layout.headerHeight)

                heading
                    .modifier(MenuPanelRise(isActive: hasAppeared, delay: 0.04))

                list
                    .modifier(MenuPanelRise(isActive: hasAppeared, delay: 0.08))

                Spacer(minLength: Spacing.x6)

                footer()
                    .modifier(MenuPanelRise(isActive: hasAppeared, delay: 0.12))
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(
                .bottom,
                proxy.safeAreaInsets.bottom > 0 ? Spacing.bottomAction : Spacing.bottomActionFromEdge
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(Color.veil)
                .ignoresSafeArea()
        }
        .onAppear { hasAppeared = true }
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape, onClose)
    }

    private var heading: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font_18_semibold(.ink)
                .lineLimit(1)

            if let subtitle {
                Text(subtitle)
                    .font_14_regular(.textZinc)
                    .lineLimit(1)
            }
        }
        .padding(.top, Spacing.x3)
        .padding(.bottom, Spacing.x6)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private var list: some View {
        VStack(spacing: 0) {
            divider
            ForEach(items) { item in
                MenuPanelRow(item: item)
                divider
            }
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.hairline)
            .frame(height: 1)
    }
}

private struct MenuPanelRow: View {
    let item: MenuPanelItem

    var body: some View {
        Button {
            Haptics.select()
            item.action()
        } label: {
            HStack(spacing: Spacing.x3) {
                Text(item.title)
                    .font_16_medium(item.role == .destructive ? .destructive : .ink)
                    .lineLimit(1)

                Spacer(minLength: 0)

                switch item.accessory {
                case .none:
                    EmptyView()
                case .chevron:
                    Icon(.iconChevronRight, size: IconSize.medium, color: .textIcon)
                        .opacity(0.5)
                case .toggle(let isOn):
                    SwitchView(isOn: isOn)
                }
            }
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.pressable)
        .accessibilityValue(accessibilityValue)
        .accessibilityAddTraits(isToggle ? .isToggle : [])
    }

    private var isToggle: Bool {
        if case .toggle = item.accessory { true } else { false }
    }

    private var accessibilityValue: String {
        if case .toggle(let isOn) = item.accessory { isOn ? "켬" : "끔" } else { "" }
    }
}

private struct MenuPanelRise: ViewModifier {
    let isActive: Bool
    let delay: TimeInterval

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(isActive ? 1 : 0)
            .offset(y: isActive || reduceMotion ? 0 : -Motion.fadeUpOffset)
            .animation(reduceMotion ? nil : Motion.slow.delay(delay), value: isActive)
    }
}

extension View {
    func menuPanel<Footer: View>(
        isPresented: Binding<Bool>,
        title: String,
        subtitle: String? = nil,
        items: [MenuPanelItem],
        @ViewBuilder footer: @escaping () -> Footer
    ) -> some View {
        overlay {
            MenuPanel(isPresented: isPresented, title: title, subtitle: subtitle, items: items, footer: footer)
        }
    }

    func menuPanel(
        isPresented: Binding<Bool>,
        title: String,
        subtitle: String? = nil,
        items: [MenuPanelItem]
    ) -> some View {
        overlay {
            MenuPanel(isPresented: isPresented, title: title, subtitle: subtitle, items: items)
        }
    }
}

#Preview {
    @Previewable @State var isPresented = true
    @Previewable @State var isDemo = false

    VStack(spacing: 0) {
        HeaderView(isMenuOpen: isPresented) { isPresented.toggle() }
        Text("내가 몰랐던 내 말버릇까지")
            .font_20_semibold(.ink)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .background(Color.background)
    .menuPanel(
        isPresented: $isPresented,
        title: "jjo",
        subtitle: "모든 기록은 이 기기에만 저장돼요",
        items: [
            MenuPanelItem(title: "데모 모드", accessory: .toggle(isOn: isDemo)) { isDemo.toggle() },
            MenuPanelItem(title: "사용법 다시 보기") {},
            MenuPanelItem(title: "개인정보 처리방침") {},
            MenuPanelItem(title: "기록 초기화", role: .destructive, accessory: .none) {}
        ]
    ) {
        TextButton("모든 기록 지우기", variant: .underline) {}
    }
}
