//
//  PitchTracker.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated struct PitchTrack: Equatable, Sendable {
    var times: [Double]
    var frequencies: [Double]
}

nonisolated enum PitchTracker {
    static func track(
        samples: [Float],
        sampleRate: Double,
        timeStep: Double,
        floor: Double,
        ceiling: Double
    ) -> PitchTrack {
        guard
            let plan = PitchAnalysisPlan(
                sampleCount: samples.count,
                sampleRate: sampleRate,
                timeStep: timeStep,
                floor: floor,
                ceiling: ceiling
            )
        else {
            return PitchTrack(times: [], frequencies: [])
        }
        let signal = samples.map(Double.init)
        let times = (0..<plan.frameCount).map(plan.time(ofFrame:))
        let table = PitchFrameAnalyzer.candidates(signal: signal, plan: plan)
        return PitchTrack(times: times, frequencies: PitchPathFinder.frequencies(table: table, plan: plan))
    }
}
