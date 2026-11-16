//
//  SincInterpolator.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated struct SincInterpolator {
    let values: UnsafePointer<Double>
    let reach: Int

    func value(at lag: Double, depth requestedDepth: Int) -> Double {
        let lower = Int(lag.rounded(.down))
        let upper = lower + 1
        if lag > Double(reach) || lag < Double(-reach) { return values[reach] }
        if lag == Double(lower) { return self[lower] }

        let depth = min(requestedDepth, upper + reach, reach - lower)
        if depth <= 0 { return self[Int((lag + 0.5).rounded(.down))] }
        if depth == 1 { return self[lower] + (lag - Double(lower)) * (self[upper] - self[lower]) }
        if depth == 2 { return cubic(at: lag, lower: lower) }

        let left = upper - depth
        let right = lower + depth
        var result = 0.0

        var angle = Double.pi * (lag - Double(lower))
        var halfSine = 0.5 * sin(angle)
        var taper = angle / (lag - Double(left) + 1)
        var taperStep = Double.pi / (lag - Double(left) + 1)
        var index = lower
        while index >= left {
            result += self[index] * (halfSine / angle * (1 + cos(taper)))
            angle += Double.pi
            taper += taperStep
            halfSine = -halfSine
            index -= 1
        }

        angle = Double.pi * (Double(upper) - lag)
        halfSine = 0.5 * sin(angle)
        taper = angle / (Double(right) - lag + 1)
        taperStep = Double.pi / (Double(right) - lag + 1)
        index = upper
        while index <= right {
            result += self[index] * (halfSine / angle * (1 + cos(taper)))
            angle += Double.pi
            taper += taperStep
            halfSine = -halfSine
            index += 1
        }
        return result
    }

    func maximum(near lag: Int, depth: Int) -> (lag: Double, value: Double) {
        if lag <= -reach { return (Double(lag), values[reach]) }
        if lag >= reach { return (Double(lag), values[reach]) }
        // Praat 은 1부터 세는 배열 위치에서 최적화하므로 수렴 허용오차가 같도록 같은 좌표로 옮긴다.
        let shift = Double(reach + 1)
        let center = Double(lag) + shift
        let best = BrentMinimizer.minimize(lower: center - 1, upper: center + 1, tolerance: 1e-10) {
            -value(at: $0 - shift, depth: depth)
        }
        return (best.x - shift, -best.value)
    }

    private subscript(index: Int) -> Double {
        values[abs(index)]
    }

    private func cubic(at lag: Double, lower: Int) -> Double {
        let upper = lower + 1
        let lowerValue = self[lower]
        let upperValue = self[upper]
        let lowerSlope = 0.5 * (upperValue - self[lower - 1])
        let upperSlope = 0.5 * (self[upper + 1] - lowerValue)
        let fromLower = lag - Double(lower)
        let toUpper = Double(upper) - lag
        let curvature = 0.5 * (upperSlope - lowerSlope)
            + (fromLower - 0.5) * (lowerSlope + upperSlope - 2 * (upperValue - lowerValue))
        return lowerValue * toUpper + upperValue * fromLower - fromLower * toUpper * curvature
    }
}
