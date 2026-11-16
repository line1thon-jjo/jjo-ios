//
//  UtteranceIntro.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

nonisolated struct UtteranceIntro: Equatable, Sendable {
    static let duration: TimeInterval = 3
    static let settled = UtteranceIntro(elapsedMs: .infinity, stepMs: 0)

    private static let standard = UnitCurve.bezier(
        startControlPoint: UnitPoint(x: 0.2, y: 0), endControlPoint: UnitPoint(x: 0, y: 1)
    )
    private static let settle = UnitCurve.bezier(
        startControlPoint: UnitPoint(x: 0.16, y: 1), endControlPoint: UnitPoint(x: 0.3, y: 1)
    )
    private static let spring = UnitCurve.bezier(
        startControlPoint: UnitPoint(x: 0.34, y: 1.56), endControlPoint: UnitPoint(x: 0.64, y: 1)
    )

    var elapsedMs: Double
    var stepMs: Double

    init(elapsedMs: Double, stepMs: Double) {
        self.elapsedMs = elapsedMs
        self.stepMs = stepMs
    }

    init(elapsed: TimeInterval, glyphCount: Int) {
        elapsedMs = elapsed * 1000
        stepMs = min(4, 1400 / Double(max(glyphCount, 1)))
    }

    func transform(_ idx: Int) -> Double {
        progress(idx, delay: 120, duration: 960, curve: Self.settle)
    }

    func emphasis(_ idx: Int) -> Double {
        progress(idx, delay: 180, duration: 320, curve: Self.standard)
    }

    func isWeightSettled(_ idx: Int) -> Bool {
        local(idx, delay: 224) >= 0
    }

    func underline(_ idx: Int) -> Double {
        min(max(local(idx, delay: 0) / 120, 0), 1)
    }

    func sweep(_ idx: Int) -> Double {
        let time = local(idx, delay: 0) / 560
        guard time > 0, time < 1 else { return 0 }
        return time < 0.4 ? Self.standard.value(at: time / 0.4) : 1 - Self.standard.value(at: (time - 0.4) / 0.6)
    }

    func pauseLine(_ idx: Int) -> Double {
        progress(idx, delay: 0, duration: 360, curve: Self.standard)
    }

    func pauseLabelOpacity(_ idx: Int) -> Double {
        progress(idx, delay: 240, duration: 200, curve: Self.standard)
    }

    func pauseLabelScale(_ idx: Int) -> Double {
        0.6 + 0.4 * progress(idx, delay: 240, duration: 480, curve: Self.spring)
    }

    private func local(_ idx: Int, delay: Double) -> Double {
        elapsedMs - Double(idx) * stepMs - delay
    }

    private func progress(_ idx: Int, delay: Double, duration: Double, curve: UnitCurve) -> Double {
        let time = local(idx, delay: delay) / duration
        if time <= 0 { return 0 }
        if time >= 1 { return 1 }
        return curve.value(at: time)
    }
}
