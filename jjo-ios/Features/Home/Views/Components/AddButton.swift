//
//  AddButton.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

struct AddButton: View {
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.open()
            action()
        } label: {
            Icon(.iconPlus, size: 18, color: .lime)
                .frame(width: Layout.floatingButton, height: Layout.floatingButton)
                .background(Color.ink, in: Circle())
                .shadow(color: .shadowFloating, radius: 10, x: 0, y: 8)
        }
        .buttonStyle(.pressable(opacity: 1, scale: 0.94))
        .accessibilityLabel("새 연습 추가")
    }
}

#Preview {
    AddButton {}
        .padding()
        .background(Color.background)
}
