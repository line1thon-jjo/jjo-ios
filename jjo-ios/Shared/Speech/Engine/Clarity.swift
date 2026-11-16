//
//  Clarity.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated enum Clarity {
    private struct Label {
        let reason: UnclearReason
        let confidence: Double
        let minRun: Int
    }

    static func detectUnclearRanges(_ syllables: [TimedSyllable], config: SpeechConfig) -> [UnclearRange] {
        let hangul = syllables.filter(\.unit.isHangul)
        let labels = hangul.map { classify($0, config: config) }
        var out: [UnclearRange] = []
        var index = 0
        while index < hangul.count {
            guard let label = labels[index] else {
                index += 1
                continue
            }
            var end = index
            while end + 1 < hangul.count, let next = labels[end + 1], next.reason == label.reason,
                  hangul[end + 1].unit.sentenceId == hangul[end].unit.sentenceId {
                end += 1
            }
            let run = labels[index...end].compactMap { $0 }
            defer { index = end + 1 }
            guard run.count >= (run.map(\.minRun).max() ?? 1) else { continue }
            let confidence = PyNumber.sum(run.map(\.confidence)) / Double(run.count)
            // 비슷한 소리의 다른 단어로 적힌 것만으로는 흐림의 증거가 약하다. 근거가 충분할 때만 낸다.
            if label.reason == .lowRecognition && confidence < config.lowRecognitionMinConf { continue }
            out.append(
                UnclearRange(
                    startIdx: hangul[index].unit.idx,
                    endIdx: hangul[end].unit.idx,
                    reason: label.reason,
                    confidence: PyNumber.round(max(0.0, min(1.0, confidence)), digits: 2)
                )
            )
        }
        return out
    }

    private static func classify(_ syllable: TimedSyllable, config: SpeechConfig) -> Label? {
        if !syllable.aligned && !syllable.inferred {
            return Label(reason: .skipped, confidence: 0.9, minRun: 1)
        }
        if syllable.inferred {
            guard let mismatch = syllable.mismatch else {
                return Label(reason: .lowRecognition, confidence: 0.7, minRun: 1)
            }
            let evidence = 0.5 * mismatch.distance + 0.5 * (1.0 - mismatch.prob)
            return Label(reason: .lowRecognition, confidence: 0.3 + 0.7 * evidence, minRun: 1)
        }
        if let confidence = syllable.confidence, confidence < config.lowProb {
            // 대본과 같은 글자로 알아들었는데 확신만 낮으면 소리는 알아들을 만했다는 뜻이라 근거를 절반만 인정한다.
            let evidence = config.matchedLowProbWeight * (1.0 - confidence)
            return Label(reason: .lowRecognition, confidence: evidence, minRun: config.minUnclearRun)
        }
        if config.lowVolumeIsUnclear && syllable.lowVolume, let volumeDb = syllable.volumeDb {
            let confidence = min(1.0, 0.5 + (-volumeDb - config.lowVolumeDb) / 16)
            return Label(reason: .lowVolume, confidence: confidence, minRun: config.minUnclearRun)
        }
        return nil
    }
}
