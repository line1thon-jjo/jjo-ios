//
//  AcousticFeaturesTests.swift
//  jjo-ios-Tests
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation
import Testing
@testable import jjo_ios

struct AcousticFeaturesTests {
    private let config = SpeechConfig.default

    @Test func suppressesBlips() {
        let db = EnergyCurve.make([(50, -70), (5, -20), (50, -70), (30, -20), (10, -70)])
        let out = AcousticFeatures.suppressBlips(db, config: config)
        #expect(out[50..<55].allSatisfy { $0 < -40 })
        #expect(out[105..<135].allSatisfy { $0 > -30 })
    }

    @Test func measuresQuietRun() {
        let db = EnergyCurve.make([(30, -20), (40, -70), (50, -20), (10, -70), (30, -20)])
        #expect(abs(PauseDetector.longestQuietMs(db: db, from: 300, to: 1200, config: config) - 400) <= 20)
        #expect(PauseDetector.longestQuietMs(db: db, from: 700, to: 1200, config: config) == 0)
        #expect(abs(PauseDetector.longestQuietMs(db: db, from: 700, to: 1300, config: config) - 100) <= 20)
    }

    @Test func snapsToSilence() {
        var db = [Double](repeating: -60, count: 300)
        for frame in 0..<100 { db[frame] = -20 }
        for frame in 160..<260 { db[frame] = -20 }
        let syllables = ScriptText.parse("가나다라").map(TimedSyllable.init)
        let times: [(Int, Int, Int)] = [(0, 500, 0), (500, 800, 0), (800, 1300, 1), (1300, 2600, 1)]
        for (syllable, time) in zip(syllables, times) {
            syllable.aligned = true
            syllable.startMs = PyNumber(time.0)
            syllable.endMs = PyNumber(time.1)
            syllable.group = time.2
        }
        #expect(AcousticFeatures.snapToSilence(syllables, db: db, config: config) == 1)
        #expect(syllables[2].startMs.value >= 1590)
        let pauses = PauseDetector.detect(syllables, config: config).pauses
        #expect(pauses.count == 1)
        #expect(abs((pauses.first?.durationMs ?? 0) - 600) <= 30)
    }

    @Test func measuresEnergy() {
        let silence = AcousticFeatures.energyDb([Float](repeating: 0, count: 16000), config: config)
        #expect(silence.count == 101)
        #expect(silence.allSatisfy { abs($0 + 160) < 1e-9 })
        let tone = AcousticFeatures.energyDb([Float](repeating: 0.5, count: 16000), config: config)
        #expect(abs(tone[50] - 20 * log10(0.5)) < 1e-6)
        #expect(tone[0] < tone[50])
    }

    @Test func mapsPitchFrames() {
        let provider: SpeechEngine.PitchProvider = { _, _, timeStep, floor, _ in
            let frequencies = (0..<40).map { floor > 60 ? 200.0 + Double($0) : ($0 % 2 == 0 ? 100.0 : 0) }
            return PitchTrack(times: (0..<40).map { Double($0) * timeStep + 0.004 }, frequencies: frequencies)
        }
        let f0 = AcousticFeatures.pitchTrack([], config: config, frameCount: 30, provider: provider)
        #expect(f0.count == 30)
        #expect(f0[0] == 200 && f0[29] == 229)
        let unvoiced: SpeechEngine.PitchProvider = { _, _, _, _, _ in
            PitchTrack(times: [0.01, 5], frequencies: [0, 90])
        }
        let empty = AcousticFeatures.pitchTrack([], config: config, frameCount: 3, provider: unvoiced)
        #expect(empty.allSatisfy { $0.isNaN })
    }

    @Test func marksFourSemitones() {
        let edges = config.pitchLevelEdgesSt
        func level(_ semitones: Double) -> Int {
            edges.count(where: { $0 <= semitones }) + 1
        }
        func marked(_ semitones: Double) -> Bool {
            [1, 2, 6, 7].contains(level(semitones))
        }
        #expect(level(0) == 4 && config.pitchMidLevel == 4)
        #expect(!marked(3.9) && !marked(-3.9) && !marked(2.5) && !marked(-2.5))
        #expect(marked(4.0) && marked(-4.1) && marked(5.0) && marked(-7.0))
        #expect(level(-7) == 1 && level(7) == 7)
    }
}
