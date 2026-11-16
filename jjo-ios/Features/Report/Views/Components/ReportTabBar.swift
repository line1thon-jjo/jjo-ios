//
//  ReportTabBar.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

struct ReportTabBar: View {
    let selection: ReportViewModel.Tab
    let onSelect: (ReportViewModel.Tab) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var indicator

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: Spacing.x2) {
                ForEach(ReportViewModel.Tab.allCases) { tab in
                    Button {
                        guard tab != selection else { return }
                        Haptics.select()
                        onSelect(tab)
                    } label: {
                        Text(tab.label)
                            .font_16_semibold(tab == selection ? .olive : .textMoss)
                            .padding(.vertical, Spacing.x3)
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .overlay(alignment: .bottom) {
                        if tab == selection {
                            Rectangle()
                                .fill(Color.olive)
                                .frame(height: 1.5)
                                .offset(y: 1)
                                .matchedGeometryEffect(id: "indicator", in: indicator)
                        }
                    }
                    .accessibilityAddTraits(tab == selection ? .isSelected : [])
                }
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .zIndex(1)

            Rectangle()
                .fill(Color.lineMint)
                .frame(height: 1)
        }
        .animation(reduceMotion ? nil : Motion.slow, value: selection)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isTabBar)
    }
}

#Preview {
    @Previewable @State var tab = ReportViewModel.Tab.summary

    ReportTabBar(selection: tab) { tab = $0 }
        .background(Color.background)
}
