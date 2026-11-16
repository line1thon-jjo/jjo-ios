//
//  RecordingStorage.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated struct RecordingStorage: Sendable {
    static let fileExtension = "m4a"

    let directory: URL

    init(directory: URL = URL.applicationSupportDirectory.appending(path: "Recordings", directoryHint: .isDirectory)) {
        self.directory = directory
    }

    func url(for fileName: String) -> URL {
        directory.appending(path: fileName)
    }

    func makeDraftURL() throws -> URL {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return url(for: "\(UUID().uuidString).\(Self.fileExtension)")
    }

    func remove(_ fileName: String) {
        try? FileManager.default.removeItem(at: url(for: fileName))
    }

    func removeAll() {
        try? FileManager.default.removeItem(at: directory)
    }
}
