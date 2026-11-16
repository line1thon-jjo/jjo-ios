//
//  PitchPathFinder.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated enum PitchPathFinder {
    static func frequencies(table: PitchCandidateTable, plan: PitchAnalysisPlan) -> [Double] {
        let frameCount = plan.frameCount
        let width = table.capacity + 1
        let correction = 0.01 / plan.timeStep
        let octaveJumpCost = PitchAnalysisPlan.octaveJumpCost * correction
        let voicedUnvoicedCost = PitchAnalysisPlan.voicedUnvoicedCost * correction

        var origins = [Int32](repeating: 0, count: frameCount * width)
        var previous = [Double](repeating: 0, count: width)
        var current = [Double](repeating: 0, count: width)
        var previousPitch = [Double](repeating: 0, count: width)
        var currentPitch = [Double](repeating: 0, count: width)
        var previousCount = 0

        for frame in 0..<frameCount {
            let count = table.counts[frame] + 1
            let base = frame * table.capacity
            let unvoiced = unvoicedStrength(intensity: table.intensities[frame])
            currentPitch[0] = 0
            current[0] = unvoiced
            for candidate in 1..<count {
                let frequency = table.frequencies[base + candidate - 1]
                let voiced = frequency > 0 && frequency < plan.ceiling
                currentPitch[candidate] = voiced ? frequency : 0
                current[candidate] = if voiced {
                    table.strengths[base + candidate - 1]
                        - PitchAnalysisPlan.octaveCost * log2(plan.ceiling / frequency)
                } else {
                    unvoiced
                }
            }

            if frame > 0 {
                for candidate in 0..<count {
                    let pitch = currentPitch[candidate]
                    var best = -1e30
                    var origin = 0
                    for source in 0..<previousCount {
                        let sourcePitch = previousPitch[source]
                        let cost: Double = if sourcePitch == 0 && pitch == 0 {
                            0
                        } else if sourcePitch == 0 || pitch == 0 {
                            voicedUnvoicedCost
                        } else {
                            octaveJumpCost * abs(log2(sourcePitch / pitch))
                        }
                        let value = previous[source] - cost + current[candidate]
                        if value > best {
                            best = value
                            origin = source
                        }
                    }
                    current[candidate] = best
                    origins[frame * width + candidate] = Int32(origin)
                }
            }
            swap(&previous, &current)
            swap(&previousPitch, &currentPitch)
            previousCount = count
        }

        var place = 0
        var best = -1e30
        for candidate in 0..<previousCount where previous[candidate] > best {
            best = previous[candidate]
            place = candidate
        }

        var result = [Double](repeating: 0, count: frameCount)
        for frame in stride(from: frameCount - 1, through: 0, by: -1) {
            if place > 0 {
                let frequency = table.frequencies[frame * table.capacity + place - 1]
                result[frame] = frequency > 0 && frequency < plan.ceiling ? frequency : 0
            }
            place = Int(origins[frame * width + place])
        }
        return result
    }

    private static func unvoicedStrength(intensity: Double) -> Double {
        let threshold = PitchAnalysisPlan.silenceThreshold / (1 + PitchAnalysisPlan.voicingThreshold)
        return PitchAnalysisPlan.voicingThreshold + max(0, 2 - intensity / threshold)
    }
}
