//
//  SyllableFeatures.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated enum SyllableFeatures {
    static func frameRange(_ syllable: TimedSyllable, frameCount: Int, config: SpeechConfig) -> Range<Int> {
        let start = max(0, min(frameCount - 1, config.frame(ms: syllable.startMs.value)))
        let end = max(start + 1, min(frameCount, config.frame(ms: syllable.endMs.value)))
        return start..<end
    }

    static func applyPitch(_ syllables: [TimedSyllable], f0: [Double], config: SpeechConfig) -> Double? {
        guard !f0.isEmpty else { return nil }
        for syllable in syllables where syllable.timed {
            let voiced = f0[frameRange(syllable, frameCount: f0.count, config: config)].filter { !$0.isNaN }
            if voiced.count >= config.minVoicedFrames {
                syllable.pitchHz = NumPy.median(voiced)
            }
        }

        let pitches = syllables.compactMap(\.pitchHz).filter { $0 != 0 }
        guard pitches.count >= 3 else { return nil }
        let medianHz = NumPy.median(pitches)

        let edges = config.pitchLevelEdgesSt
        for syllable in syllables {
            guard let pitchHz = syllable.pitchHz else { continue }
            let semitones = 12 * log2(pitchHz / medianHz)
            syllable.pitchSt = semitones
            var level = edges.count(where: { $0 <= semitones }) + 1
            // 표시 대상에서 뺄 글자는 한 칸 안쪽(3 또는 5단계)으로 내린다. 방향은 유지된다.
            let marked = level <= 2 || level >= edges.count
            let excluded = (syllable.unit.isSentenceEnd && !config.pitchMarkSentenceEnd)
                || (level <= 2 && !config.pitchMarkLow)
            if marked && excluded {
                level = level <= 2 ? 3 : edges.count - 1
            }
            syllable.pitchLevel = level
        }
        return medianHz
    }

    @discardableResult
    static func applyVolume(_ syllables: [TimedSyllable], db: [Double], config: SpeechConfig) -> Double? {
        guard !db.isEmpty else { return nil }
        var values: [(index: Int, level: Double)] = []
        for (index, syllable) in syllables.enumerated() where syllable.timed && syllable.unit.isHangul {
            let range = frameRange(syllable, frameCount: db.count, config: config)
            values.append((index, NumPy.percentile(Array(db[range]), 75)))
        }
        guard values.count >= 5 else { return nil }
        let medianDb = NumPy.median(values.map(\.level))
        for (index, level) in values {
            let relative = level - medianDb
            syllables[index].volumeDb = relative
            syllables[index].lowVolume = relative <= -config.lowVolumeDb
        }
        return medianDb
    }

    static func applyStretch(_ syllables: [TimedSyllable], config: SpeechConfig) {
        let measured = syllables.filter { $0.aligned && $0.unit.isHangul && $0.durMs.value > 0 }
        guard measured.count >= 5 else { return }

        func weight(_ syllable: TimedSyllable) -> Double {
            1.0 + (syllable.unit.hasBatchim ? config.batchimWeight : 0.0)
        }

        let base = NumPy.median(measured.map { $0.durMs.value / weight($0) })
        for syllable in measured {
            let expected = base * weight(syllable)
            let duration = syllable.durMs
            syllable.stretchRatio = (duration / expected).rounded(digits: 2)
            let limit = syllable.unit.isSentenceEnd ? config.endStretchRatio : config.stretchRatio
            syllable.stretch = syllable.stretchRatio >= limit
                && duration.value - expected >= Double(config.stretchMinExtraMs)
        }
    }
}
