//
//  PageIndicator.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

struct PageIndicator: View {
    let count: Int
    let current: Int
    let onSelect: (Int) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { index in
                Button {
                    onSelect(index)
                } label: {
                    RoundedRectangle(cornerRadius: Radius.indicator)
                        .fill(index == current ? Color.ink : Color.indicatorIdle)
                        .frame(width: index == current ? 40 : 20, height: 6)
                        .padding(.vertical, 19)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.pressable)
                .padding(.vertical, -19)
                .accessibilityLabel("\(index + 1)번째 안내")
                .accessibilityAddTraits(index == current ? .isSelected : [])
            }
        }
        .animation(reduceMotion ? nil : Motion.slow, value: current)
    }
}

#Preview {
    @Previewable @State var current = 0

    PageIndicator(count: 3, current: current) { current = $0 }
        .padding()
        .background(Color.backgroundOnboarding)
}
