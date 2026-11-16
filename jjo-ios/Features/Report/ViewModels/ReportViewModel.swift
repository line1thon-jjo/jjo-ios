//
//  ReportViewModel.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

@Observable
final class ReportViewModel {
    enum Tab: String, CaseIterable, Identifiable {
        case summary
        case detail

        var id: String { rawValue }

        var label: String {
            switch self {
            case .summary: "요약"
            case .detail: "상세 분석"
            }
        }
    }

    enum Phase: Equatable {
        case missing
        case failed(AnalysisErrorCode?)
        case result
    }

    let practiceID: UUID
    let player = RangePlayer()

    private(set) var recordingID: UUID
    private(set) var practice: Practice?
    private(set) var recording: Recording?
    // SwiftData 는 관계 객체를 붙잡아 두지 않으면 새 인스턴스를 내주어 상태 변화 알림이 끊긴다
    private(set) var report: Report?
    private(set) var content: ReportContent?
    private(set) var isUnreadable = false
    private(set) var sawProgress = false
    private(set) var hasCelebrated = false
    private(set) var tab: Tab = .summary
    private(set) var focusPace: UtteranceAnalysis.PaceLabel?
    private(set) var detailShownAt: Date?
    var isGuideOpen = false

    @ObservationIgnored private var loadedSource: ReportContent.Source?

    init(practiceID: UUID, recordingID: UUID) {
        self.practiceID = practiceID
        self.recordingID = recordingID
    }

    var status: ReportStatus? { report?.status }

    var title: String? { practice?.title }

    var attempts: [ReportAttempt<UUID>] {
        ReportTransform.attempts(
            (practice?.recordings ?? []).map {
                ReportAttempt(
                    recordingId: $0.id, attemptNo: $0.attemptNo, recordedAt: $0.createdAt, status: $0.report?.status
                )
            }
        )
    }

    var durationLabel: String? {
        recording.map { ReportAttempts.formatDuration($0.durationMs) }
    }

    var phase: Phase {
        guard recording != nil else { return .missing }
        if status == .failed {
            return .failed(report?.failureCode.flatMap(AnalysisErrorCode.init(rawValue:)))
        }
        return isUnreadable ? .failed(nil) : .result
    }

    var showsAnalyzing: Bool {
        guard phase == .result, let status else { return false }
        return status.isInProgress || (status == .completed && sawProgress && !hasCelebrated)
    }

    var isAnalysisDone: Bool { status == .completed }

    func syncKey(revision: Int) -> String {
        "\(recordingID.uuidString)-\(recording == nil ? "UNLOADED" : status?.rawValue ?? "NONE")-\(revision)"
    }

    func load(using environment: AppEnvironment) {
        practice = environment.store.practice(id: practiceID)
        recording = environment.store.recording(id: recordingID)
        report = recording?.report
    }

    func select(_ id: UUID, using environment: AppEnvironment) {
        guard id != recordingID else { return }
        player.unload()
        recordingID = id
        content = nil
        loadedSource = nil
        isUnreadable = false
        sawProgress = false
        hasCelebrated = false
        focusPace = nil
        isGuideOpen = false
        detailShownAt = tab == .detail ? .now : nil
        load(using: environment)
    }

    func sync(using environment: AppEnvironment) async {
        guard let recording else { return }
        let id = recording.id
        if report !== recording.report {
            report = recording.report
        }

        switch status {
        case nil:
            environment.runner.start(recordingID: id)
            sawProgress = true
        case .pending, .analyzing:
            sawProgress = true
            if !environment.runner.isQueued(id) {
                environment.runner.start(recordingID: id)
            }
        case .completed:
            await loadContent(for: recording, using: environment)
        case .failed:
            player.unload()
        }
    }

    func retry(using environment: AppEnvironment) {
        guard let recording else {
            load(using: environment)
            return
        }
        content = nil
        loadedSource = nil
        isUnreadable = false
        sawProgress = false
        hasCelebrated = false
        environment.runner.start(recordingID: recording.id)
    }

    func celebrate() {
        hasCelebrated = true
    }

    func setTab(_ next: Tab) {
        if next != tab {
            player.stop()
        }
        tab = next
        if next == .detail, detailShownAt == nil {
            detailShownAt = .now
        }
    }

    func focus(_ pace: UtteranceAnalysis.PaceLabel) {
        focusPace = pace
        setTab(.detail)
    }

    func togglePace(_ pace: UtteranceAnalysis.PaceLabel) {
        focusPace = focusPace == pace ? nil : pace
    }

    func play(_ item: FeedbackItem) {
        player.toggle(PlaybackRange(item))
    }

    func playSegment(_ index: Int) {
        guard let segments = content?.utterance.segments, segments.indices.contains(index) else { return }
        player.toggle(PlaybackRange(segments[index], index: index)) { timeMs in
            GlyphBuilder.findChar(segments, at: timeMs)
        }
    }

    private func loadContent(for recording: Recording, using environment: AppEnvironment) async {
        let previous = ReportAttempts.previous(attempts, before: recording.attemptNo)
            .flatMap { attempt in practice?.recordings.first { $0.id == attempt.recordingId } }
        let source = ReportContent.Source(
            resultData: report?.resultData,
            feedbackData: report?.feedbackData,
            previousResultData: previous?.report?.resultData
        )
        guard source != loadedSource else { return }

        let id = recording.id
        let url = environment.store.storage.url(for: recording.fileName)
        let loaded = await Self.build(source)
        guard id == recordingID, !Task.isCancelled else { return }

        loadedSource = source
        content = loaded
        isUnreadable = loaded == nil
        if loaded == nil {
            player.unload()
        } else {
            player.load(FileManager.default.fileExists(atPath: url.path) ? url : nil)
        }
    }

    @concurrent
    private static func build(_ source: ReportContent.Source) async -> ReportContent? {
        ReportContent.make(source)
    }
}
