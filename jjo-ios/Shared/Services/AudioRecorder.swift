//
//  AudioRecorder.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import AVFAudio
import Foundation
import Observation

@Observable
final class AudioRecorder {
    enum Status: Equatable {
        case idle
        case recording
        case paused
        case done
    }

    enum Limit {
        static let minimumMs = 2_000
        static let maximumMs = 595_000
        static let tick = Duration.milliseconds(200)
    }

    private(set) var status: Status = .idle
    private(set) var seconds = 0
    private(set) var durationMs = 0
    private(set) var level: Float = 0
    private(set) var reachedLimit = false
    private(set) var fileURL: URL?
    private(set) var errorMessage: String?

    private let storage: RecordingStorage
    private var recorder: AVAudioRecorder?
    private var ticker: Task<Void, Never>?
    private var interruptions: Task<Void, Never>?

    init(storage: RecordingStorage = RecordingStorage()) {
        self.storage = storage
        interruptions = Task { [weak self] in
            let notifications = NotificationCenter.default.notifications(named: AVAudioSession.interruptionNotification)
            for await notification in notifications {
                let raw = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
                guard raw == AVAudioSession.InterruptionType.began.rawValue else { continue }
                self?.pause()
            }
        }
    }

    deinit {
        interruptions?.cancel()
    }

    var isTooShort: Bool { status == .done && durationMs < Limit.minimumMs }

    func start() async {
        reset()
        guard await AVAudioApplication.requestRecordPermission() else {
            errorMessage = "마이크 권한을 허용해주세요."
            return
        }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothHFP])
            try session.setActive(true)

            let url = try storage.makeDraftURL()
            let created = try AVAudioRecorder(
                url: url,
                settings: [
                    AVFormatIDKey: kAudioFormatMPEG4AAC,
                    AVSampleRateKey: 48_000,
                    AVNumberOfChannelsKey: 1,
                    AVEncoderBitRateKey: 128_000,
                    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                ]
            )
            created.isMeteringEnabled = true
            guard created.record() else { throw CocoaError(.fileWriteUnknown) }
            recorder = created
            fileURL = url
            status = .recording
            startTicker()
        } catch {
            discardFile()
            errorMessage = "녹음을 시작하지 못했어요. 다시 시도해 주세요."
        }
    }

    func pause() {
        guard status == .recording, let recorder else { return }
        recorder.pause()
        ticker?.cancel()
        level = 0
        status = .paused
    }

    func resume() {
        guard status == .paused, let recorder, recorder.record() else { return }
        status = .recording
        startTicker()
    }

    func stop() {
        finish(hitLimit: false)
    }

    func reset() {
        ticker?.cancel()
        recorder?.stop()
        recorder = nil
        discardFile()
        seconds = 0
        durationMs = 0
        level = 0
        reachedLimit = false
        errorMessage = nil
        status = .idle
        deactivateSession()
    }

    func takeFile() -> (url: URL, durationMs: Int)? {
        guard status == .done, let fileURL else { return nil }
        let taken = (fileURL, durationMs)
        self.fileURL = nil
        return taken
    }

    private func finish(hitLimit: Bool) {
        guard let recorder, status == .recording || status == .paused else { return }
        ticker?.cancel()
        let elapsedMs = Int((recorder.currentTime * 1000).rounded())
        recorder.stop()
        self.recorder = nil
        durationMs = max(1, elapsedMs)
        seconds = elapsedMs / 1000
        level = 0
        reachedLimit = hitLimit
        status = .done
        deactivateSession()
    }

    private func startTicker() {
        ticker?.cancel()
        ticker = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: Limit.tick)
                guard !Task.isCancelled, let self, let recorder = self.recorder else { return }
                let elapsedMs = Int(recorder.currentTime * 1000)
                if elapsedMs >= Limit.maximumMs {
                    self.finish(hitLimit: true)
                    return
                }
                recorder.updateMeters()
                self.level = Self.normalized(recorder.averagePower(forChannel: 0))
                self.seconds = elapsedMs / 1000
            }
        }
    }

    private func discardFile() {
        if let fileURL {
            try? FileManager.default.removeItem(at: fileURL)
        }
        fileURL = nil
    }

    private func deactivateSession() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private static func normalized(_ decibels: Float) -> Float {
        let floor: Float = -50
        return max(0, min(1, (decibels - floor) / -floor))
    }
}
