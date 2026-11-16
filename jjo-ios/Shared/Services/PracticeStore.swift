//
//  PracticeStore.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation
import SwiftData

@Observable
final class PracticeStore {
    let container: ModelContainer
    let storage: RecordingStorage

    private var context: ModelContext { container.mainContext }
    private(set) var revision = 0

    init(container: ModelContainer, storage: RecordingStorage = RecordingStorage()) {
        self.container = container
        self.storage = storage
    }

    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        try ModelContainer(
            for: Practice.self, Recording.self, Report.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: inMemory)
        )
    }

    func practices() -> [Practice] {
        let descriptor = FetchDescriptor<Practice>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        return (try? context.fetch(descriptor)) ?? []
    }

    func practice(id: UUID) -> Practice? {
        var descriptor = FetchDescriptor<Practice>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    func recording(id: UUID) -> Recording? {
        var descriptor = FetchDescriptor<Recording>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    @discardableResult
    func createPractice(title: String, script: String) -> Practice {
        let practice = Practice(title: title, script: script)
        context.insert(practice)
        commit()
        return practice
    }

    func rename(_ practice: Practice, title: String) {
        practice.title = title
        commit()
    }

    @discardableResult
    func addRecording(to practice: Practice, fileURL: URL, durationMs: Int) -> Recording {
        let attemptNo = (practice.recordings.map(\.attemptNo).max() ?? 0) + 1
        let recording = Recording(
            attemptNo: attemptNo,
            scriptSnapshot: practice.script,
            fileName: fileURL.lastPathComponent,
            durationMs: durationMs
        )
        recording.practice = practice
        context.insert(recording)
        practice.updatedAt = .now
        commit()
        return recording
    }

    func delete(_ practice: Practice) {
        practice.recordings.forEach { storage.remove($0.fileName) }
        context.delete(practice)
        commit()
    }

    func deleteAll() {
        practices().forEach { context.delete($0) }
        storage.removeAll()
        commit()
    }

    func commit() {
        try? context.save()
        revision += 1
    }
}
