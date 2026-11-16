//
//  ScriptViewModel.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation
import Observation

@Observable
final class ScriptViewModel {
    private(set) var script = ""
    private(set) var isCreating = false
    var alertMessage: String?

    private var creation: Task<UUID?, Never>?

    var count: Int { script.scalarCount }

    func update(_ text: String) {
        script = text.scalarCount > ScriptValidator.maxLength ? text.scalarPrefix(ScriptValidator.maxLength) : text
    }

    func importFile(at url: URL) async {
        let imported = await ScriptImport.load(from: url)
        if let text = imported.script {
            update(text)
        }
        alertMessage = imported.message
    }

    func create(in store: PracticeStore) async -> UUID? {
        guard !isCreating else { return nil }
        guard ScriptValidator.error(in: script) == nil else {
            alertMessage = ScriptMessage.empty
            return nil
        }

        isCreating = true
        let script = script
        let task = Task { () -> UUID? in
            let title = await TitleWriter.title(for: script)
            guard !Task.isCancelled else { return nil }
            return store.createPractice(title: title, script: script).id
        }
        creation = task
        let id = await task.value
        isCreating = false
        return id
    }

    func cancelCreation() {
        creation?.cancel()
        creation = nil
    }
}
