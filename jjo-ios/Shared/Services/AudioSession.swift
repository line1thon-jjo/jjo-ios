//
//  AudioSession.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import AVFAudio
import Foundation

nonisolated enum AudioSession {
    // 세션 전환은 수백 ms 동안 호출 스레드를 막을 수 있어 메인 밖의 직렬 큐에서 순서대로 처리한다
    private static let queue = DispatchQueue(label: "com.awesomejjo.jjo.audio-session")

    static func activateForRecording() async throws {
        try await run {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothHFP])
            try session.setActive(true)
        }
    }

    static func activateForPlayback() async {
        try? await run {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio)
            try session.setActive(true)
        }
    }

    static func deactivate() {
        queue.async {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }

    private static func run(_ work: @escaping @Sendable () throws -> Void) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async {
                continuation.resume(with: Result { try work() })
            }
        }
    }
}
