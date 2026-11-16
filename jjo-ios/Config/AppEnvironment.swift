//
//  AppEnvironment.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftData
import SwiftUI

@Observable
final class AppEnvironment {
    let settings: AppSettings
    let store: PracticeStore
    let runner: AnalysisRunner

    init(settings: AppSettings = AppSettings(), container: ModelContainer) {
        self.settings = settings
        store = PracticeStore(container: container)
        runner = AnalysisRunner(store: store)
    }

    static func live() -> AppEnvironment {
        let container = (try? PracticeStore.makeContainer())
            ?? (try? PracticeStore.makeContainer(inMemory: true))
        guard let container else { fatalError("ModelContainer unavailable") }
        return AppEnvironment(container: container)
    }

    static func preview() -> AppEnvironment {
        guard let container = try? PracticeStore.makeContainer(inMemory: true) else {
            fatalError("ModelContainer unavailable")
        }
        return AppEnvironment(container: container)
    }
}
