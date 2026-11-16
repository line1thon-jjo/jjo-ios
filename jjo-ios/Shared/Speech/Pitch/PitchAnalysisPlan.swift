//
//  PitchAnalysisPlan.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated struct PitchAnalysisPlan: Sendable {
    static let periodsPerWindow = 3.0
    static let interpolationDepth = 0.5
    static let minimumCandidates = 15
    static let silenceThreshold = 0.03
    static let voicingThreshold = 0.45
    static let octaveCost = 0.01
    static let octaveJumpCost = 0.35
    static let voicedUnvoicedCost = 0.14

    let sampleCount: Int
    let samplePeriod: Double
    let timeStep: Double
    let floor: Double
    let ceiling: Double
    let windowLength: Int
    let halfWindow: Int
    let longestPeriod: Int
    let peakHalfSpan: Int
    let maximumLag: Int
    let interpolationReach: Int
    let transformLength: Int
    let frameCount: Int
    let firstTime: Double
    let candidateCapacity: Int

    init?(sampleCount: Int, sampleRate: Double, timeStep: Double, floor: Double, ceiling: Double) {
        guard sampleCount > 0, sampleRate > 0, floor > 0, ceiling > floor, floor.isFinite, ceiling.isFinite else {
            return nil
        }
        let samplePeriod = 1 / sampleRate
        let duration = samplePeriod * Double(sampleCount)
        let windowDuration = Self.periodsPerWindow / floor
        let step = timeStep > 0 ? timeStep : windowDuration / 4
        guard floor >= Self.periodsPerWindow / duration, windowDuration <= duration else { return nil }

        let halfWindow = Int((windowDuration / samplePeriod).rounded(.down)) / 2 - 1
        guard halfWindow >= 2 else { return nil }
        let windowLength = halfWindow * 2
        let frameCount = Int(((duration - windowDuration) / step).rounded(.down)) + 1
        guard frameCount >= 1 else { return nil }

        var transformLength = 1
        while Double(transformLength) < Double(windowLength) * (1 + Self.interpolationDepth) {
            transformLength *= 2
        }
        let firstSampleTime = 0.5 * samplePeriod
        let midTime = firstSampleTime - 0.5 * samplePeriod + 0.5 * duration

        self.sampleCount = sampleCount
        self.samplePeriod = samplePeriod
        self.timeStep = step
        self.floor = floor
        self.ceiling = min(ceiling, 0.5 / samplePeriod)
        self.windowLength = windowLength
        self.halfWindow = halfWindow
        let longestPeriod = Int((1 / samplePeriod / floor).rounded(.down))
        self.longestPeriod = longestPeriod
        self.peakHalfSpan = longestPeriod / 2 + 1
        self.maximumLag = min(Int((Double(windowLength) / Self.periodsPerWindow).rounded(.down)) + 2, windowLength)
        self.interpolationReach = Int(Double(windowLength) * Self.interpolationDepth)
        self.transformLength = max(transformLength, 4)
        self.frameCount = frameCount
        self.firstTime = midTime - 0.5 * (Double(frameCount) * step) + 0.5 * step
        self.candidateCapacity = max(Self.minimumCandidates, Int((ceiling / floor).rounded(.down)))
    }

    var firstSampleTime: Double {
        0.5 * samplePeriod
    }

    func time(ofFrame index: Int) -> Double {
        // arm64 Praat 빌드는 이 식을 FMA 로 계산한다. 샘플 수가 홀수면 반올림 한 번 차이로 창이 한 샘플 밀린다.
        firstTime.addingProduct(Double(index), timeStep)
    }

    func lowSample(at time: Double) -> Int {
        Int(((time - firstSampleTime) / samplePeriod).rounded(.down))
    }
}
