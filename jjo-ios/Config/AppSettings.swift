//
//  AppSettings.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

@Observable
final class AppSettings {
    enum Key {
        static let onboardingCompleted = "settings.onboardingCompleted"
    }

    private let defaults: UserDefaults

    var onboardingCompleted: Bool {
        didSet { defaults.set(onboardingCompleted, forKey: Key.onboardingCompleted) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        onboardingCompleted = defaults.bool(forKey: Key.onboardingCompleted)
    }
}
