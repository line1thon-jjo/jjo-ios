//
//  JjoApp.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

@main
struct JjoApp: App {
    @State private var environment: AppEnvironment

    init() {
        FontRegistrar.registerIfNeeded()
        _environment = State(initialValue: AppEnvironment.live())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(environment)
                .preferredColorScheme(.light)
        }
    }
}
