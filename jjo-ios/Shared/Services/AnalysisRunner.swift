//
//  AnalysisRunner.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation
import UIKit

@Observable
final class AnalysisRunner {
    private struct Outcome: Sendable {
        var result: AnalysisResult?
        var feedback: StoredFeedback?
        var failure: AnalysisErrorCode?
    }

    private let store: PracticeStore
    private var queue: [UUID] = []
    private var worker: Task<Void, Never>?
    private(set) var activeRecordingID: UUID?

    init(store: PracticeStore) {
        self.store = store
    }

    func isQueued(_ recordingID: UUID) -> Bool {
        activeRecordingID == recordingID || queue.contains(recordingID)
    }

    func start(recordingID: UUID) {
        guard !isQueued(recordingID), let recording = store.recording(id: recordingID) else { return }
        let report = recording.report ?? Report()
        if recording.report == nil {
            recording.report = report
        }
        report.status = .pending
        report.resultData = nil
        report.feedbackData = nil
        report.failureCode = nil
        report.completedAt = nil
        store.commit()

        queue.append(recordingID)
        drain()
    }

    // 분석 도중 앱이 종료되면 진행 중 상태로 남으므로, 다음 실행 때 다시 대기열에 넣는다
    func resumeInterrupted() {
        for practice in store.practices() {
            for recording in practice.attempts where recording.report?.status.isInProgress == true {
                if !isQueued(recording.id) {
                    queue.append(recording.id)
                }
            }
        }
        drain()
    }

    private func drain() {
        guard worker == nil else { return }
        worker = Task { [weak self] in
            while let self, let next = self.dequeue() {
                await self.run(next)
            }
            self?.worker = nil
        }
    }

    private func dequeue() -> UUID? {
        guard !queue.isEmpty else {
            activeRecordingID = nil
            return nil
        }
        let next = queue.removeFirst()
        activeRecordingID = next
        return next
    }

    private func run(_ recordingID: UUID) async {
        guard let recording = store.recording(id: recordingID), let report = recording.report else { return }
        report.status = .analyzing
        store.commit()

        let background = UIApplication.shared.beginBackgroundTask(withName: "jjo.analysis")
        let outcome = await Self.analyze(
            url: store.storage.url(for: recording.fileName),
            script: recording.scriptSnapshot
        )
        UIApplication.shared.endBackgroundTask(background)

        guard let current = store.recording(id: recordingID)?.report else { return }
        if let result = outcome.result {
            current.resultData = try? JSONEncoder().encode(result)
            current.feedbackData = outcome.feedback.flatMap { try? JSONEncoder().encode($0) }
            current.schemaVersion = result.version
            current.failureCode = nil
            current.status = current.resultData == nil ? .failed : .completed
        } else {
            current.failureCode = (outcome.failure ?? .internal).rawValue
            current.status = .failed
        }
        current.completedAt = .now
        store.commit()
    }

    @concurrent
    private static func analyze(url: URL, script: String) async -> Outcome {
        do {
            let samples = try AudioDecoder.samples(from: url)
            let words = try await Transcriber.words(from: url)
            let result = try SpeechEngine.analyze(samples: samples, script: script, words: words)
            let feedback = await FeedbackWriter.write(for: result)
            return Outcome(result: result, feedback: feedback)
        } catch let error as AnalysisError {
            return Outcome(failure: error.code)
        } catch {
            return Outcome(failure: .internal)
        }
    }
}
