//
//  PitchTrackerTests.swift
//  jjo-ios-Tests
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation
import Testing
@testable import jjo_ios

struct PitchTrackerTests {
    private static let sampleRate = 16_000.0

    private static func tone(_ partials: [(frequency: Double, amplitude: Double)], count: Int = 16_000) -> [Float] {
        (0..<count).map { index in
            let phase = 2 * Double.pi * Double(index) / sampleRate
            return Float(partials.reduce(0) { $0 + $1.amplitude * sin($1.frequency * phase) })
        }
    }

    private static func glide(from start: Double, to end: Double, count: Int) -> [Float] {
        var cycles = 0.0
        return (0..<count).map { index in
            cycles += start + (end - start) * Double(index) / Double(count)
            return Float(0.5 * sin(2 * Double.pi * cycles / sampleRate))
        }
    }

    private static func noise(count: Int, amplitude: Float) -> [Float] {
        var state: UInt64 = 0x2545_F491_4F6C_DD1D
        return (0..<count).map { _ in
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return (Float(state >> 40) / Float(1 << 24) * 2 - 1) * amplitude
        }
    }

    private static func track(_ samples: [Float], floor: Double = 60, ceiling: Double = 500) -> PitchTrack {
        PitchTracker.track(samples: samples, sampleRate: sampleRate, timeStep: 0.01, floor: floor, ceiling: ceiling)
    }

    @Test func tracksSine() {
        let track = Self.track(Self.tone([(220, 0.5)]))
        #expect(track.frequencies.count == 96)
        #expect(track.frequencies.allSatisfy { abs($0 - 220) < 0.05 })
    }

    @Test func matchesPraat() {
        let track = Self.track(Self.tone([(150, 0.4), (300, 0.2), (450, 0.1)]))
        let expected = [0: 149.99991069708267, 10: 149.99991069708267, 47: 149.9999253862111, 95: 149.99992538801692]
        #expect(track.frequencies.count == 96)
        for (frame, frequency) in expected {
            #expect(abs(track.frequencies[frame] - frequency) < 1e-5)
        }
    }

    @Test func matchesFrameTimes() {
        let wide = Self.track(Self.tone([(220, 0.5)]))
        #expect(wide.times.count == 96)
        #expect(abs(wide.times[0] - 0.025) < 1e-12)
        #expect(abs(wide.times[95] - 0.975) < 1e-12)

        let narrow = Self.track(Self.tone([(220, 0.5)]), floor: 165, ceiling: 500)
        #expect(narrow.times.count == 99)
        #expect(narrow.times.count == narrow.frequencies.count)
    }

    @Test func findsMissingFundamental() {
        let track = Self.track(Self.tone([(280, 0.3), (420, 0.3), (560, 0.2)]))
        #expect(track.frequencies.allSatisfy { abs($0 - 140) < 0.5 })
    }

    @Test func followsGlide() {
        let samples = [Float](repeating: 0, count: 8_000) + Self.glide(from: 120, to: 240, count: 16_000)
        let track = Self.track(samples, floor: 75, ceiling: 600)
        let expected = [49: 121.2305628858045, 60: 134.40570702747542, 100: 182.40156156351583, 146: 237.6024070277948]
        #expect(track.times.count == 147)
        #expect(abs(track.times[0] - 0.02) < 1e-12)
        #expect(track.frequencies[..<49].allSatisfy { $0 == 0 })
        for (frame, frequency) in expected {
            #expect(abs(track.frequencies[frame] - frequency) < 1e-4)
        }
    }

    @Test func silenceUnvoiced() {
        let track = Self.track([Float](repeating: 0, count: 16_000))
        #expect(track.times.count == 96)
        #expect(track.frequencies.allSatisfy { $0 == 0 })
    }

    @Test func noiseUnvoiced() {
        let track = Self.track(Self.noise(count: 32_000, amplitude: 0.1))
        let voiced = track.frequencies.filter { $0 > 0 }.count
        #expect(track.times.count == 196)
        #expect(voiced <= 2)
    }

    @Test func shortInputEmpty() {
        #expect(Self.track([]) == PitchTrack(times: [], frequencies: []))
        #expect(Self.track(Self.tone([(220, 0.5)], count: 100)).times.isEmpty)
        #expect(Self.track(Self.tone([(220, 0.5)], count: 799)).times.isEmpty)
        #expect(Self.track(Self.tone([(220, 0.5)], count: 800)).times.count == 1)
    }

    @Test func rejectsInvalidRange() {
        let samples = Self.tone([(220, 0.5)])
        #expect(Self.track(samples, floor: 0, ceiling: 500).times.isEmpty)
        #expect(Self.track(samples, floor: 500, ceiling: 60).times.isEmpty)
    }

    @Test func ignoresOffset() {
        let samples = Self.tone([(180, 0.3), (360, 0.1)])
        let plain = Self.track(samples)
        let shifted = Self.track(samples.map { $0 + 0.3 })
        #expect(plain.times == shifted.times)
        #expect(zip(plain.frequencies, shifted.frequencies).allSatisfy { abs($0 - $1) < 0.01 })
    }

    @Test func survivesClipping() {
        let samples = Self.tone([(200, 4)]).map { min(1, max(-1, $0)) }
        let track = Self.track(samples)
        #expect(track.frequencies.allSatisfy { abs($0 - 200) < 0.5 })
    }

    @Test func handlesLongAudio() {
        let unit = Self.tone([(130, 0.4), (260, 0.2)]) + [Float](repeating: 0, count: 4_000)
        let samples = (0..<60).flatMap { _ in unit }
        let track = Self.track(samples)
        let voiced = track.frequencies.filter { $0 > 0 }
        #expect(track.times.count == 7_496)
        #expect(voiced.count > 5_000)
        #expect(voiced.allSatisfy { abs($0 - 130) < 2 })
    }
}
