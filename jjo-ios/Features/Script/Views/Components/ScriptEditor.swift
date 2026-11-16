//
//  ScriptEditor.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

struct ScriptEditor: View {
    @Binding var text: String
    let count: Int
    var maxLength = ScriptValidator.maxLength
    var isSnapshot = false
    var isFocused: FocusState<Bool>.Binding

    private static let locale = Locale(identifier: "ko_KR")

    var body: some View {
        VStack(spacing: 0) {
            field
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(Color.surface)
                .overlay(alignment: .top) { border }
                .overlay(alignment: .bottom) { border }

            HStack {
                Text("최대 \(formatted(maxLength))자")
                Spacer(minLength: 0)
                Text("\(formatted(count)) / \(formatted(maxLength))자")
                    .monospacedDigit()
                    .accessibilityLabel("\(maxLength)자 중 \(count)자 입력")
            }
            .pretendard(.regular, 14, .textBody, lineHeight: .natural, tracking: false)
            .frame(height: 33)
        }
    }

    private var field: some View {
        TextEditor(text: $text)
            .pretendard(.regular, 16, .textBody, lineHeight: .percent160, tracking: false)
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .focused(isFocused)
            .disabled(isSnapshot)
            .padding(.vertical, 6)
            .padding(.horizontal, 3)
            .overlay(alignment: .topLeading) {
                if text.isEmpty {
                    Text(ScriptMessage.placeholder)
                        .pretendard(.regular, 16, .textBody, lineHeight: .percent160, tracking: false)
                        .padding(.vertical, 14)
                        .padding(.horizontal, Spacing.x2)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
            .accessibilityLabel("발표 대본")
            .accessibilityHint(ScriptMessage.placeholder)
    }

    private var border: some View {
        Rectangle()
            .fill(Color.line)
            .frame(height: 1)
    }

    private func formatted(_ value: Int) -> String {
        value.formatted(.number.locale(Self.locale))
    }
}
