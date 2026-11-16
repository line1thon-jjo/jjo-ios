//
//  BrentMinimizer.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated enum BrentMinimizer {
    private static let goldenSection = (3 - 5.0.squareRoot()) / 2
    private static let rootEpsilon = Double.ulpOfOne.squareRoot()
    private static let iterationLimit = 60

    static func minimize(
        lower: Double,
        upper: Double,
        tolerance: Double,
        function: (Double) -> Double
    ) -> (x: Double, value: Double) {
        var low = lower
        var high = upper
        var third = low + goldenSection * (high - low)
        var thirdValue = function(third)
        var best = third
        var bestValue = thirdValue
        var second = third
        var secondValue = thirdValue

        for _ in 0..<iterationLimit {
            let middle = 0.5 * (low + high)
            let allowance = rootEpsilon * abs(best) + tolerance / 3
            if abs(best - middle) + 0.5 * (high - low) <= 2 * allowance { break }

            var step = goldenSection * (best < middle ? high - best : low - best)
            if abs(best - second) >= allowance {
                let secondTerm = (best - second) * (bestValue - thirdValue)
                var denominator = (best - third) * (bestValue - secondValue)
                var numerator = (best - third) * denominator - (best - second) * secondTerm
                denominator = 2 * (denominator - secondTerm)
                if denominator > 0 {
                    numerator = -numerator
                } else {
                    denominator = -denominator
                }
                let insideLow = numerator > denominator * (low - best + 2 * allowance)
                let insideHigh = numerator < denominator * (high - best - 2 * allowance)
                if abs(numerator) < abs(step * denominator), insideLow, insideHigh {
                    step = numerator / denominator
                }
            }
            if abs(step) < allowance {
                step = step > 0 ? allowance : -allowance
            }

            let trial = best + step
            let trialValue = function(trial)
            if trialValue <= bestValue {
                if trial < best {
                    high = best
                } else {
                    low = best
                }
                third = second
                thirdValue = secondValue
                second = best
                secondValue = bestValue
                best = trial
                bestValue = trialValue
            } else {
                if trial < best {
                    low = trial
                } else {
                    high = trial
                }
                if trialValue <= secondValue || second == best {
                    third = second
                    thirdValue = secondValue
                    second = trial
                    secondValue = trialValue
                } else if trialValue <= thirdValue || third == best || third == second {
                    third = trial
                    thirdValue = trialValue
                }
            }
        }
        return (best, bestValue)
    }
}
