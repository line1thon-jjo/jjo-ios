//
//  AppMenu.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation
import Observation

@Observable
final class AppMenu {
    var isPresented = false
    var isResetSheetPresented = false
    var isReplayingOnboarding = false

    static var versionText: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "버전 \(version) (\(build))"
    }

    func toggle() {
        if isPresented {
            Haptics.close()
        } else {
            Haptics.open()
        }
        isPresented.toggle()
    }

    func replayOnboarding() {
        isPresented = false
        isReplayingOnboarding = true
    }

    func dismissAll() {
        isResetSheetPresented = false
        isPresented = false
    }
}
