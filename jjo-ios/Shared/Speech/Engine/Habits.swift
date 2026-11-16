//
//  Habits.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

// 같은 종류가 minHabitCount 회 이상 반복될 때만 습관으로 보고한다.
nonisolated enum Habits {
    static func detect(_ syllables: [TimedSyllable], pauses: inout [Pause], config: SpeechConfig) -> [Habit] {
        var order: [HabitType] = []
        var found: [HabitType: [IdxRange]] = [:]
        var marks: [Int: [HabitType]] = [:]

        func add(_ type: HabitType, _ idx: Int, mark: Bool = true) {
            if found[type] == nil { order.append(type) }
            found[type, default: []].append(IdxRange(startIdx: idx, endIdx: idx))
            if mark { marks[idx, default: []].append(type) }
        }

        var sentenceOrder: [Int] = []
        var bySentence: [Int: [TimedSyllable]] = [:]
        for syllable in syllables where syllable.unit.isHangul && syllable.aligned {
            if bySentence[syllable.unit.sentenceId] == nil { sentenceOrder.append(syllable.unit.sentenceId) }
            bySentence[syllable.unit.sentenceId, default: []].append(syllable)
        }

        for sentenceId in sentenceOrder {
            guard let members = bySentence[sentenceId], let last = members.last, last.unit.isSentenceEnd else {
                continue
            }
            if last.stretch { add(.endStretch, last.unit.idx) }
            if last.lowVolume { add(.endFade, last.unit.idx) }
            if !last.unit.isQuestionEnd, let lastPitch = last.pitchSt {
                let pitched = members.count(where: { $0.pitchSt != nil })
                let head = members.dropLast(2).compactMap(\.pitchSt)
                if pitched >= config.endRiseMinPitched && !head.isEmpty
                    && lastPitch - NumPy.median(head) >= config.endRiseSt {
                    add(.endRise, last.unit.idx)
                }
            }
        }

        // 어절 안의 여러 글자에 걸쳐 늘이면 마지막 글자만으로는 길이가 모자라 보여서, 어절 안에서 늘어난 마지막 글자를 표시한다.
        var word: [TimedSyllable] = []
        for syllable in syllables where syllable.unit.isHangul {
            word.append(syllable)
            if syllable.unit.boundaryAfter == .none { continue }
            let stretched = word.filter(\.stretch)
            if let lastStretched = stretched.last, syllable.stretch || stretched.count >= 2,
               !word.contains(where: \.unit.isSentenceEnd) {
                add(.midStretch, lastStretched.unit.idx)
            }
            word = []
        }

        let hangul = syllables.filter(\.unit.isHangul)
        for (a, b) in zip(hangul, hangul.dropFirst()) {
            if a.aligned && b.aligned && a.unit.strength >= 3
                && b.startMs.value - a.endMs.value < Double(config.noBreakMs) {
                add(.noBreak, a.unit.idx)
            }
        }

        var pauseType: [Int: HabitType] = [:]
        for pause in pauses {
            let type: HabitType
            if !pause.expected && pause.durationMs >= config.habitPauseMs {
                type = .midPause
            } else if pause.expected && pause.durationMs >= config.longPauseMs
                && pause.relativeLength >= config.longPauseRelative {
                type = .longPause
            } else {
                continue
            }
            pauseType[pause.afterIdx] = type
            add(type, pause.afterIdx, mark: false)
        }

        var habits: [Habit] = []
        var keep: Set<HabitType> = []
        for type in order {
            guard let occurrences = found[type], occurrences.count >= config.minHabitCount else { continue }
            keep.insert(type)
            let sorted = stableSorted(occurrences) { $0.startIdx < $1.startIdx }
            habits.append(Habit(type: type, count: sorted.count, occurrences: sorted, firstIdx: sorted[0].startIdx))
        }
        habits = stableSorted(habits) { ($1.count, $0.firstIdx) < ($0.count, $1.firstIdx) }

        for index in pauses.indices {
            guard let type = pauseType[pauses[index].afterIdx], keep.contains(type) else { continue }
            pauses[index].isHabit = true
            pauses[index].habitType = type
        }
        for syllable in syllables {
            syllable.habitTypes = (marks[syllable.unit.idx] ?? []).filter(keep.contains)
        }
        return habits
    }

    private static func stableSorted<Element>(
        _ values: [Element],
        by precedes: (Element, Element) -> Bool
    ) -> [Element] {
        values.enumerated()
            .sorted { precedes($0.element, $1.element) || (!precedes($1.element, $0.element) && $0.offset < $1.offset) }
            .map(\.element)
    }
}
