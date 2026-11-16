//
//  SwitchView.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

struct SwitchView: View {
    let isOn: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        RoundedRectangle(cornerRadius: Radius.toggle)
            .fill(isOn ? Color.lime : Color.lineZinc)
            .frame(width: 44, height: 26)
            .overlay(alignment: .leading) {
                Circle()
                    .fill(Color.pureWhite)
                    .frame(width: 20, height: 20)
                    .shadow(color: .shadowKnob, radius: 1.5, x: 0, y: 1)
                    .offset(x: isOn ? 21 : 3)
            }
            .animation(reduceMotion ? nil : Motion.base, value: isOn)
            .accessibilityHidden(true)
    }
}

#Preview {
    @Previewable @State var isOn = false

    Button { isOn.toggle() } label: { SwitchView(isOn: isOn) }
        .buttonStyle(.plain)
        .padding()
}
