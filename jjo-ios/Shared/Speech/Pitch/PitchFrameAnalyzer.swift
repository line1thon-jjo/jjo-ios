//
//  PitchFrameAnalyzer.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Dispatch
import Foundation
import Synchronization

nonisolated final class PitchFrameAnalyzer {
    private static let overflowDepth = 30
    private static let refinementDepth = 70
    private static let deepRefinementDepth = 700

    private let plan: PitchAnalysisPlan
    private let globalPeak: Double
    private let autocorrelator: PitchAutocorrelator
    private let window: [Double]
    private let windowCorrelation: [Double]
    private let buffer: UnsafeMutablePointer<Double>
    private let correlation: UnsafeMutablePointer<Double>
    private var lags: [Int]

    init?(plan: PitchAnalysisPlan, globalPeak: Double) {
        guard let autocorrelator = PitchAutocorrelator(length: plan.transformLength) else { return nil }
        let length = plan.windowLength
        let window = (1...length).map { 0.5 - 0.5 * cos(Double($0) * 2 * Double.pi / Double(length + 1)) }
        let buffer = UnsafeMutablePointer<Double>.allocate(capacity: plan.transformLength)
        buffer.initialize(repeating: 0, count: plan.transformLength)
        buffer.update(from: window, count: length)
        autocorrelator.transform(buffer)
        let zeroLag = buffer[0]

        self.plan = plan
        self.globalPeak = globalPeak
        self.autocorrelator = autocorrelator
        self.window = window
        self.windowCorrelation = (0...plan.interpolationReach).map { buffer[$0] / zeroLag }
        self.buffer = buffer
        correlation = .allocate(capacity: plan.interpolationReach + 1)
        correlation.initialize(repeating: 0, count: plan.interpolationReach + 1)
        lags = Array(repeating: 0, count: plan.candidateCapacity)
    }

    deinit {
        buffer.deallocate()
        correlation.deallocate()
    }

    static func candidates(signal: [Double], plan: PitchAnalysisPlan) -> PitchCandidateTable {
        let capacity = plan.candidateCapacity - 1
        let globalPeak = peak(of: signal)
        guard globalPeak > 0 else { return PitchCandidateTable(frameCount: plan.frameCount, capacity: capacity) }

        let workers = max(1, min(ProcessInfo.processInfo.activeProcessorCount, plan.frameCount / 64))
        let stride = (plan.frameCount + workers - 1) / workers
        let chunks = Mutex([PitchCandidateTable?](repeating: nil, count: workers))
        DispatchQueue.concurrentPerform(iterations: workers) { worker in
            let frames = min(plan.frameCount, worker * stride)..<min(plan.frameCount, (worker + 1) * stride)
            let chunk = candidates(signal: signal, plan: plan, globalPeak: globalPeak, frames: frames)
            chunks.withLock { $0[worker] = chunk }
        }
        return PitchCandidateTable(joining: chunks.withLock { $0.compactMap(\.self) }, capacity: capacity)
    }

    private static func candidates(
        signal: [Double],
        plan: PitchAnalysisPlan,
        globalPeak: Double,
        frames: Range<Int>
    ) -> PitchCandidateTable {
        let capacity = plan.candidateCapacity - 1
        var table = PitchCandidateTable(frameCount: frames.count, capacity: capacity)
        guard let analyzer = PitchFrameAnalyzer(plan: plan, globalPeak: globalPeak) else { return table }
        signal.withUnsafeBufferPointer { samples in
            table.frequencies.withUnsafeMutableBufferPointer { frequencies in
                table.strengths.withUnsafeMutableBufferPointer { strengths in
                    for (row, frame) in frames.enumerated() {
                        let slots = (row * capacity)..<((row + 1) * capacity)
                        let result = analyzer.analyze(
                            frame: frame,
                            samples: samples,
                            frequencies: UnsafeMutableBufferPointer(rebasing: frequencies[slots]),
                            strengths: UnsafeMutableBufferPointer(rebasing: strengths[slots])
                        )
                        table.counts[row] = result.count
                        table.intensities[row] = result.intensity
                    }
                }
            }
        }
        return table
    }

    private static func peak(of signal: [Double]) -> Double {
        let mean = signal.reduce(0, +) / Double(signal.count)
        return signal.reduce(0) { max($0, abs($1 - mean)) }
    }

    private func analyze(
        frame: Int,
        samples: UnsafeBufferPointer<Double>,
        frequencies: UnsafeMutableBufferPointer<Double>,
        strengths: UnsafeMutableBufferPointer<Double>
    ) -> (count: Int, intensity: Double) {
        let localPeak = load(frame: frame, samples: samples)
        let intensity = localPeak > globalPeak ? 1 : localPeak / globalPeak
        guard localPeak > 0 else { return (0, intensity) }

        autocorrelator.transform(buffer)
        let zeroLag = buffer[0]
        guard zeroLag > 0 else { return (0, intensity) }
        let reach = plan.interpolationReach
        correlation[0] = 1
        for lag in 1...reach {
            correlation[lag] = buffer[lag] / (zeroLag * windowCorrelation[lag])
        }

        let interpolator = SincInterpolator(values: UnsafePointer(correlation), reach: reach)
        let count = collect(interpolator: interpolator, frequencies: frequencies, strengths: strengths)
        for slot in 0..<count {
            let deep = frequencies[slot] > 0.3 / plan.samplePeriod
            let best = interpolator.maximum(
                near: lags[slot],
                depth: deep ? Self.deepRefinementDepth : Self.refinementDepth
            )
            frequencies[slot] = 1 / plan.samplePeriod / best.lag
            strengths[slot] = Self.reflected(best.value)
        }
        return (count, intensity)
    }

    private func load(frame: Int, samples: UnsafeBufferPointer<Double>) -> Double {
        let low = plan.lowSample(at: plan.time(ofFrame: frame))
        let high = low + 1
        let length = plan.windowLength

        let meanStart = max(0, high - plan.longestPeriod)
        let meanEnd = min(samples.count - 1, low + plan.longestPeriod)
        var sum = 0.0
        if meanStart <= meanEnd {
            for index in meanStart...meanEnd {
                sum += samples[index]
            }
        }
        let mean = sum / Double(max(1, meanEnd - meanStart + 1))

        let start = high - plan.halfWindow
        let peakRange = max(0, plan.halfWindow - plan.peakHalfSpan)..<min(length, plan.halfWindow + plan.peakHalfSpan)
        var localPeak = 0.0
        for offset in 0..<length {
            let index = start + offset
            let value = samples.indices.contains(index) ? (samples[index] - mean) * window[offset] : 0
            if peakRange.contains(offset) {
                localPeak = max(localPeak, abs(value))
            }
            buffer[offset] = value
        }
        (buffer + length).update(repeating: 0, count: plan.transformLength - length)
        return localPeak
    }

    private func collect(
        interpolator: SincInterpolator,
        frequencies: UnsafeMutableBufferPointer<Double>,
        strengths: UnsafeMutableBufferPointer<Double>
    ) -> Int {
        let capacity = frequencies.count
        let threshold = 0.5 * PitchAnalysisPlan.voicingThreshold
        let end = min(plan.maximumLag, plan.interpolationReach)
        var count = 0
        var lag = 2
        while lag < end {
            defer { lag += 1 }
            let value = correlation[lag]
            guard value > threshold, value > correlation[lag - 1], value >= correlation[lag + 1] else { continue }
            let slope = 0.5 * (correlation[lag + 1] - correlation[lag - 1])
            let curvature = 2 * value - correlation[lag - 1] - correlation[lag + 1]
            let frequency = 1 / plan.samplePeriod / (Double(lag) + slope / curvature)
            let strength = Self.reflected(
                interpolator.value(at: 1 / plan.samplePeriod / frequency, depth: Self.overflowDepth)
            )

            var slot = count
            if count < capacity {
                count += 1
            } else {
                var weakest = Double.greatestFiniteMagnitude
                slot = -1
                for index in 0..<capacity {
                    let local = localStrength(frequency: frequencies[index], strength: strengths[index])
                    if local < weakest {
                        weakest = local
                        slot = index
                    }
                }
                if slot < 0 || localStrength(frequency: frequency, strength: strength) <= weakest {
                    continue
                }
            }
            frequencies[slot] = frequency
            strengths[slot] = strength
            lags[slot] = lag
        }
        return count
    }

    private func localStrength(frequency: Double, strength: Double) -> Double {
        strength - PitchAnalysisPlan.octaveCost * log2(plan.ceiling / frequency)
    }

    private static func reflected(_ strength: Double) -> Double {
        strength > 1 ? 1 / strength : strength
    }
}
