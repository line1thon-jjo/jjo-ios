//
//  RecordCircleButton.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

struct RecordCircleButton<Label: View>: View {
    enum Tone {
        case main
        case dark
        case red

        var color: Color {
            switch self {
            case .main: .lime
            case .dark: .recordDark
            case .red: .recordRedDark
            }
        }
    }

    let tone: Tone
    let title: String
    var isDisabled = false
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    var body: some View {
        Button(action: action) {
            label()
                .frame(width: 48, height: 48)
                .background(tone.color, in: Circle())
        }
        .buttonStyle(.pressable(opacity: 0.8, scale: 0.94))
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1)
        .accessibilityLabel(title)
    }
}
