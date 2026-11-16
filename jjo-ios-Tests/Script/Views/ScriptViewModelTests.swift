//
//  ScriptViewModelTests.swift
//  jjo-ios-Tests
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation
import Testing
@testable import jjo_ios

@MainActor
struct ScriptViewModelTests {
    @Test func limitsLength() {
        let viewModel = ScriptViewModel()
        viewModel.update(String(repeating: "가", count: 1501))
        #expect(viewModel.count == 1500)
    }

    @Test func rejectsBlank() async throws {
        let viewModel = ScriptViewModel()
        viewModel.update("  \n ")
        let store = PracticeStore(container: try PracticeStore.makeContainer(inMemory: true))

        #expect(await viewModel.create(in: store) == nil)
        #expect(viewModel.alertMessage == ScriptMessage.empty)
        #expect(store.practices().isEmpty)
    }
}
