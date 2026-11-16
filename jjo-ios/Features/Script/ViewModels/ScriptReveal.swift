//
//  ScriptReveal.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

@Observable
final class ScriptReveal {
    private(set) var viewModel = ScriptViewModel()
    private(set) var origin: CGPoint?
    private(set) var isCovering = false
    private(set) var isRevealed = false

    private var transition: Task<Void, Never>?

    func open(from origin: CGPoint, reduceMotion: Bool, navigation: NavigationManager) {
        guard !isCovering, navigation.path.isEmpty else { return }
        viewModel = ScriptViewModel()

        guard !reduceMotion else {
            self.origin = nil
            navigation.push(.script)
            return
        }

        self.origin = origin
        isRevealed = false
        isCovering = true
        transition = Task {
            try? await Task.sleep(for: .milliseconds(20))
            isRevealed = true
            try? await Task.sleep(for: .milliseconds(520))
            navigation.instantly { $0.push(.script) }
            try? await Task.sleep(for: .milliseconds(80))
            isCovering = false
        }
    }

    func close(reduceMotion: Bool, navigation: NavigationManager) {
        guard !isCovering else { return }
        viewModel.cancelCreation()

        guard !reduceMotion, origin != nil, navigation.path == [.script] else {
            navigation.pop()
            return
        }

        isRevealed = true
        isCovering = true
        transition = Task {
            try? await Task.sleep(for: .milliseconds(20))
            navigation.instantly { $0.pop() }
            try? await Task.sleep(for: .milliseconds(60))
            isRevealed = false
            try? await Task.sleep(for: .milliseconds(440))
            isCovering = false
        }
    }
}
