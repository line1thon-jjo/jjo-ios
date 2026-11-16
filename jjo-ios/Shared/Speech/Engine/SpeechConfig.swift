//
//  SpeechConfig.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated struct SpeechConfig: Equatable, Sendable {
    static let `default` = SpeechConfig()

    var sampleRate = 16000
    var hopMs = 10
    var minAudioMs = 1500
    var maxAudioS = 600

    var minAlignCoverage = 0.5
    var warnAlignCoverage = 0.85
    var anchorMinChars = 2
    var refineByEnergy = true
    var refineLambda = 0.3
    var edgeExtendMs = 150
    var edgeTrimDb = 25.0
    var minSyllableMs = 60

    var minWordMsPerChar = 40
    var blipMs = 90
    var blipGapMs = 150
    var gapMergeMs = 120
    var gapMinSegmentMs = 60
    var gapMinFillRatio = 0.4
    var defaultSyllableMs = 180
    var hintPadMs = 80

    var pitchFloorHz = 60.0
    var pitchCeilingHz = 500.0
    var pitchFloorRatio = 0.75
    var pitchCeilingRatio = 2.5
    var minVoicedFrames = 3
    // 화면은 1·2·6·7단계(본인 평균에서 ±4반음 이상)만 표시한다. 2반음은 글자의 절반 가까이가 표시되어 4반음으로 정했다.
    var pitchLevelEdgesSt: [Double] = [-6.0, -4.0, -1.0, 1.0, 4.0, 6.0]
    // 문장 끝 글자는 억양이 자연스럽게 오르내려서 표시 대상에서 뺀다.
    var pitchMarkSentenceEnd = false
    // 문장 중간의 '낮음' 표시는 실제 청취와 맞는 비율이 낮아 검증 전까지 끈다.
    var pitchMarkLow = false

    var lowVolumeDb = 14.0
    var lowVolumeIsUnclear = false
    var lowRecognitionMinConf = 0.65
    var matchedLowProbWeight = 0.5

    var stretchRatio = 2.2
    var endStretchRatio = 2.6
    var stretchMinExtraMs = 120
    var batchimWeight = 0.2

    var pauseMinMs = 200
    var habitPauseMs = 400
    var longPauseMs = 700
    var longPauseRelative = 2.0
    var typicalPauseDefaultMs = 500
    var noBreakMs = 120

    var phraseSplitPauseMs = 300
    var minPhraseSyllables = 4
    var fastRatio = 1.4
    var slowRatio = 0.7
    var phraseMinAlignedRatio = 0.8
    var plausibleRate: ClosedRange<Double> = 1.5...11.0

    var lowProb = 0.4
    var minUnclearRun = 2

    var strayMinMs = 150
    var strayMarginMs = 30
    var strayBelowPeakDb = 25.0
    var strayVoicedRatio = 0.5
    var strayLoudBelowPeakDb = 12.0
    var deviationLongSyllables = 5
    var deviationLongProb = 0.7
    var detachGapMs = 120
    var keepCharRatio = 0.8

    var substituteMinDistance = 0.5
    var scriptMatchWarn = 0.7
    var deviationMinSyllables = 3
    var deviationMinProb = 0.8
    var deviationMinWordProb = 0.5
    // 길게(5음절 이상) 다른 말로 인식된 구간은 한 단어가 잘못 들려도 통째로 버리지 않는다.
    var deviationLongMinWordProb = 0.4

    var endRiseSt = 3.0
    var endRiseMinPitched = 4
    var minHabitCount = 2

    var pitchMidLevel: Int { pitchLevelEdgesSt.count / 2 + 1 }

    func frame(ms: Double) -> Int {
        Int((ms / Double(hopMs)).rounded(.toNearestOrEven))
    }
}
