//
//  AnalysisRunner.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation
import OSLog
import UIKit

nonisolated enum AnalysisStage: Equatable, Sendable {
    case preparing(progress: Double)
    case transcribing
    case analyzing
    case writingFeedback

    var message: String? {
        switch self {
        case .preparing(let progress):
            "음성 인식 모델을 내려받고 있어요. 처음 한 번만 필요해요. (\(Int(progress * 100))%)"
        case .transcribing, .analyzing, .writingFeedback:
            nil
        }
    }
}

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
    private(set) var stage: AnalysisStage?

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
        ) { [weak self] stage in
            Task { @MainActor [weak self] in self?.stage = stage }
        }
        stage = nil
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
    private static func analyze(
        url: URL,
        script: String,
        onStage: @Sendable @escaping (AnalysisStage) -> Void
    ) async -> Outcome {
        let clock = ContinuousClock()
        var mark = clock.now
        func lap(_ name: String) {
            let now = clock.now
            logger.info("\(name, privacy: .public) \(String(describing: now - mark), privacy: .public)")
            mark = now
        }
        do {
            logger.info("start \(url.lastPathComponent, privacy: .public)")
            onStage(.preparing(progress: 0))
            try await Transcriber.prepare { onStage(.preparing(progress: $0)) }
            lap("prepare")
            onStage(.transcribing)
            let samples = try AudioDecoder.samples(from: url)
            lap("decode")
            let words = try await Transcriber.words(from: url)
            lap("transcribe")
            onStage(.analyzing)
            let result = try SpeechEngine.analyze(samples: samples, script: script, words: words)
            lap("engine")
            onStage(.writingFeedback)
            let feedback = await FeedbackWriter.write(for: result)
            lap("feedback")
            return Outcome(result: result, feedback: feedback)
        } catch let error as AnalysisError {
            logger.error("failed \(error.code.rawValue, privacy: .public) \(error.message, privacy: .public)")
            return Outcome(failure: error.code)
        } catch {
            logger.error("failed \(error.localizedDescription, privacy: .public)")
            return Outcome(failure: .internal)
        }
    }

    private nonisolated static let logger = Logger(subsystem: "com.awesomejjo.jjo", category: "analysis")
}
