//
//  AnalysisResult.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated enum SpeedLabel: String, Codable, Sendable {
    case fast = "FAST"
    case normal = "NORMAL"
    case slow = "SLOW"
}

nonisolated enum HabitType: String, Codable, Sendable, CaseIterable {
    case endRise = "END_RISE"
    case endStretch = "END_STRETCH"
    case endFade = "END_FADE"
    case midStretch = "MID_STRETCH"
    case midPause = "MID_PAUSE"
    case longPause = "LONG_PAUSE"
    case noBreak = "NO_BREAK"
}

nonisolated enum PauseBoundary: String, Codable, Sendable {
    case wordInternal = "WORD_INTERNAL"
    case word = "WORD"
    case comma = "COMMA"
    case line = "LINE"
    case sentence = "SENTENCE"
}

nonisolated enum UnclearReason: String, Codable, Sendable {
    case lowVolume = "LOW_VOLUME"
    case lowRecognition = "LOW_RECOGNITION"
    case skipped = "SKIPPED"
}

nonisolated enum DisfluencyType: String, Codable, Sendable {
    case filler = "FILLER"
    case `repeat` = "REPEAT"
    case insertion = "INSERTION"
    case straySound = "STRAY_SOUND"
}

nonisolated enum SpokenKind: String, Codable, Sendable {
    case replaced = "REPLACED"
    case added = "ADDED"
}

nonisolated enum AnalysisErrorCode: String, Codable, Sendable {
    case emptyScript = "EMPTY_SCRIPT"
    case audioNotFound = "AUDIO_NOT_FOUND"
    case audioDecodeFailed = "AUDIO_DECODE_FAILED"
    case audioTooShort = "AUDIO_TOO_SHORT"
    case audioTooLong = "AUDIO_TOO_LONG"
    case noSpeech = "NO_SPEECH"
    case alignmentLowCoverage = "ALIGNMENT_LOW_COVERAGE"
    case engineUnavailable = "ENGINE_UNAVAILABLE"
    case `internal` = "INTERNAL"
}

nonisolated struct AnalysisError: Error, Equatable, Sendable {
    let code: AnalysisErrorCode
    let message: String
}

nonisolated struct IdxRange: Codable, Equatable, Sendable {
    var startIdx: Int
    var endIdx: Int
}

nonisolated struct UnclearRange: Codable, Equatable, Sendable {
    var startIdx: Int
    var endIdx: Int
    var reason: UnclearReason
    var confidence: Double
}

nonisolated struct Syllable: Codable, Equatable, Sendable {
    var idx: Int
    var char: String
    var startMs: Int
    var endMs: Int
    var pitchHz: Double?
    var pitchSt: Double?
    var pitchLevel: Int = 4
    var volumeDb: Double?
    var lowVolume = false
    var stretch = false
    var stretchRatio: Double = 1.0
    var aligned = true
    var inferred = false
    var confidence: Double?
    var isHabit = false
    var habitTypes: [HabitType] = []
}

nonisolated struct Pause: Codable, Equatable, Sendable {
    var afterIdx: Int
    var durationMs: Int
    var boundary: PauseBoundary
    var expected = false
    var relativeLength: Double = 1.0
    var isHabit = false
    var habitType: HabitType?
}

nonisolated struct Disfluency: Codable, Equatable, Sendable {
    var type: DisfluencyType
    var beforeIdx: Int
    var startMs: Int
    var endMs: Int
    var text: String?
}

nonisolated struct SpokenDifference: Codable, Equatable, Sendable {
    var kind: SpokenKind
    var startIdx: Int
    var endIdx: Int
    var spoken: String
    var scriptText: String?
}

nonisolated struct Phrase: Codable, Equatable, Sendable {
    var startIdx: Int
    var endIdx: Int
    var speedSyllPerSec: Double
    var speedRatio: Double
    var speedLabel: SpeedLabel
}

nonisolated struct Habit: Codable, Equatable, Sendable {
    var type: HabitType
    var count: Int
    var occurrences: [IdxRange]
    var firstIdx: Int
}

nonisolated struct AnalysisSummary: Codable, Equatable, Sendable {
    var avgSyllablesPerSec: Double
    var articulationSyllablesPerSec: Double
    var medianPitchHz: Double?
    var typicalPauseMs: Int?
    var alignedRatio: Double
    var scriptMatchRatio: Double?
}

nonisolated struct AnalysisResult: Codable, Equatable, Sendable {
    static let schemaVersion = "1.1"

    var version = AnalysisResult.schemaVersion
    var durationMs: Int
    var spokenText = ""
    var syllables: [Syllable]
    var pauses: [Pause]
    var phrases: [Phrase]
    var habits: [Habit]
    var mismatchedRanges: [IdxRange] = []
    var unclearRanges: [UnclearRange] = []
    var disfluencies: [Disfluency] = []
    var spokenDifferences: [SpokenDifference] = []
    var warnings: [String] = []
    var summary: AnalysisSummary
}

nonisolated struct WordTiming: Codable, Equatable, Sendable {
    var text: String
    var start: Double
    var end: Double
    var prob: Double = 1.0
}
