//
//  RangePlayer.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import AVFoundation
import Foundation

@Observable
final class RangePlayer {
    private(set) var isAvailable = false
    private(set) var playing: PlaybackRange?
    private(set) var position = -1

    @ObservationIgnored private var player: AVAudioPlayer?
    @ObservationIgnored private var ticker: Task<Void, Never>?

    func load(_ url: URL?) {
        stop()
        player = url.flatMap { try? AVAudioPlayer(contentsOf: $0) }
        player?.prepareToPlay()
        isAvailable = player != nil
    }

    func unload() {
        stop()
        player = nil
        isAvailable = false
    }

    func toggle(_ range: PlaybackRange, locate: ((Double) -> Int)? = nil) {
        if playing == range {
            stop()
        } else {
            play(range, locate: locate)
        }
    }

    func stop() {
        ticker?.cancel()
        ticker = nil
        player?.pause()
        playing = nil
        position = -1
    }

    private func play(_ range: PlaybackRange, locate: ((Double) -> Int)?) {
        guard let player else { return }
        ticker?.cancel()

        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio)
        try? session.setActive(true)

        player.currentTime = TimeInterval(range.startMs) / 1000
        playing = range
        position = locate?(Double(range.startMs)) ?? -1

        guard player.play() else {
            stop()
            return
        }

        ticker = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(16))
                guard !Task.isCancelled, let self, self.tick(range, locate: locate) else { return }
            }
        }
    }

    private func tick(_ range: PlaybackRange, locate: ((Double) -> Int)?) -> Bool {
        guard let player, playing == range else { return false }

        let timeMs = player.currentTime * 1000
        // 파일 끝까지 재생되거나 전화 등으로 끊기면 isPlaying 이 먼저 꺼진다
        if !player.isPlaying || timeMs >= Double(range.endMs) {
            stop()
            return false
        }

        let next = locate?(max(timeMs, Double(range.startMs))) ?? -1
        if next != position {
            position = next
        }
        return true
    }
}
