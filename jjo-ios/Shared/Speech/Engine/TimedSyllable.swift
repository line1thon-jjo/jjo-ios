//
//  TimedSyllable.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated struct TimeSpan: Equatable, Sendable {
    var start: PyNumber
    var end: PyNumber
}

nonisolated struct RecognitionMismatch: Equatable, Sendable {
    var distance: Double
    var prob: Double
}

nonisolated final class TimedSyllable {
    let unit: ScriptUnit
    var startMs = PyNumber.zero
    var endMs = PyNumber.zero
    var aligned = false
    var inferred = false
    var group: Int?
    var confidence: Double?
    var pitchHz: Double?
    var pitchSt: Double?
    var pitchLevel = 4
    var volumeDb: Double?
    var lowVolume = false
    var stretch = false
    var stretchRatio = 1.0
    var habitTypes: [HabitType] = []
    var hint: TimeSpan?
    var mismatch: RecognitionMismatch?
    var snapStart = false
    var snapEnd = false
    var silStart: PyNumber?

    var durMs: PyNumber { endMs - startMs }

    var timed: Bool { aligned || inferred }

    init(unit: ScriptUnit) {
        self.unit = unit
    }
}
