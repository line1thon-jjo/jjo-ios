//
//  FeedbackCandidates.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated enum FeedbackCandidates {
    static let quoteMax = 40

    static func build(from result: AnalysisResult) -> [FeedbackCandidate] {
        // 위치가 본문을 벗어난 잘못된 분석 결과면 서버처럼 후보 없음으로 처리한다
        (try? candidates(from: result)) ?? []
    }

    static func quoteWindow(
        _ text: String, baseStart: Int, baseEnd: Int, anchorStart: Int, anchorEnd: Int
    ) -> (start: Int, end: Int) {
        quoteWindow(
            ScalarText(text), baseStart: baseStart, baseEnd: baseEnd, anchorStart: anchorStart, anchorEnd: anchorEnd
        )
    }
}

private nonisolated extension FeedbackCandidates {
    nonisolated enum Group: Int {
        case habit
        case pace
        case pause
    }

    nonisolated struct Event {
        var group: Group
        var kind: FeedbackKind
        var anchorStart: Int
        var anchorEnd: Int
        var base: (start: Int, end: Int)?
        var severity: Double
        var metrics: FeedbackCandidate.Metrics
    }

    static func candidates(from result: AnalysisResult) throws -> [FeedbackCandidate] {
        let text = ScalarText(result.spokenText)
        guard text.count > 0 else { return [] }
        let syllables = result.syllables.stableSorted(by: \.idx)
        let segments = ReportTransform.segments(result)
        var candidates: [FeedbackCandidate] = []
        for event in events(result) {
            let source: (start: Int, end: Int)
            if let base = event.base {
                source = base
            } else if let segment = segments.first(where: {
                $0.startIdx <= event.anchorStart && event.anchorStart <= $0.endIdx
            }) {
                source = (segment.startIdx, segment.endIdx)
            } else {
                continue
            }
            let window = quoteWindow(
                text,
                baseStart: max(0, source.start),
                baseEnd: min(text.count - 1, source.end),
                anchorStart: event.anchorStart,
                anchorEnd: event.anchorEnd
            )
            guard window.start <= window.end else { continue }
            // 같은 구절을 두 번 인용하지 않는다(앞선, 더 심한 후보만 남김)
            guard !candidates.contains(where: { $0.startIdx == window.start && $0.endIdx == window.end }) else {
                continue
            }
            guard let play = playRange(
                syllables,
                start: window.start,
                end: window.end,
                extendAfter: event.kind.isPause ? event.anchorEnd : nil,
                durationMs: result.durationMs
            ) else { continue }
            candidates.append(
                FeedbackCandidate(
                    id: candidates.count + 1,
                    kind: event.kind,
                    quote: flattened(text.string(from: window.start, to: window.end + 1)),
                    startIdx: window.start,
                    endIdx: window.end,
                    startMs: play.start,
                    endMs: play.end,
                    metrics: event.metrics,
                    focus: try focus(text, event)
                )
            )
        }
        return candidates
    }

    static func events(_ result: AnalysisResult) -> [Event] {
        let syllableByIdx = Dictionary(result.syllables.map { ($0.idx, $0) }, uniquingKeysWith: { _, last in last })
        var events: [Event] = []
        var pauseHabitSpots: Set<Int> = []

        for habit in ReportTransform.habits(result) {
            guard let source = result.habits.first(where: { $0.type == habit.type }) else { continue }
            let kind = FeedbackKind(habit: habit.type)
            for occurrence in source.occurrences {
                var metrics = FeedbackCandidate.Metrics(habitCount: habit.count)
                // 많이 반복된 종류가 먼저, 같은 종류 안에서는 더 길게 쉬거나 더 많이 늘인 곳이 먼저
                var severity = Double(habit.count) * 1_000_000
                if kind.isPause {
                    let pause = result.pauses.first {
                        occurrence.startIdx <= $0.afterIdx && $0.afterIdx <= occurrence.endIdx
                    }
                    if let pause {
                        metrics.durationMs = pause.durationMs
                        severity += Double(pause.durationMs)
                    }
                    if occurrence.startIdx <= occurrence.endIdx {
                        pauseHabitSpots.formUnion(occurrence.startIdx...occurrence.endIdx)
                    }
                } else if let syllable = syllableByIdx[occurrence.endIdx], syllable.stretch {
                    metrics.stretchRatio = syllable.stretchRatio
                    severity += syllable.stretchRatio * 1000
                }
                events.append(
                    Event(
                        group: .habit, kind: kind, anchorStart: occurrence.startIdx, anchorEnd: occurrence.endIdx,
                        base: nil, severity: severity, metrics: metrics
                    )
                )
            }
        }

        for phrase in result.phrases where phrase.speedLabel != .normal {
            let ratio = phrase.speedRatio
            let severity = phrase.speedLabel == .fast ? ratio : (ratio > 0 ? 1 / ratio : 0)
            events.append(
                Event(
                    group: .pace, kind: .pace, anchorStart: phrase.startIdx, anchorEnd: phrase.startIdx,
                    base: (phrase.startIdx, phrase.endIdx), severity: severity,
                    metrics: FeedbackCandidate.Metrics(speed: phrase.speedLabel, speedRatio: ratio)
                )
            )
        }

        for pause in result.pauses
        where ReportTransform.isNotablePause(pause) && !pauseHabitSpots.contains(pause.afterIdx) {
            events.append(
                Event(
                    group: .pause, kind: .pause, anchorStart: pause.afterIdx, anchorEnd: pause.afterIdx,
                    base: nil, severity: Double(pause.durationMs),
                    metrics: FeedbackCandidate.Metrics(durationMs: pause.durationMs)
                )
            )
        }

        // 반복된 습관 → 빠름·느림 → 쉼. 같은 묶음 안에서는 심한 것, 그다음 앞쪽 순
        return events.stableSorted { lhs, rhs in
            if lhs.group != rhs.group { return lhs.group.rawValue < rhs.group.rawValue }
            if lhs.severity != rhs.severity { return lhs.severity > rhs.severity }
            return lhs.anchorStart < rhs.anchorStart
        }
    }

    static func trimmed(_ text: ScalarText, _ start: Int, _ end: Int) throws -> (start: Int, end: Int) {
        var start = start
        var end = end
        while start <= end, try text.checked(start).isPythonSpace {
            start += 1
        }
        while end >= start, try text.checked(end).isPythonSpace {
            end -= 1
        }
        return (start, end)
    }

    // 40자를 넘으면 앞부분만 쓰되, 문제 위치가 밖으로 밀리면 그 위치가 들어가게 자른다
    static func quoteWindow(
        _ text: ScalarText, baseStart: Int, baseEnd: Int, anchorStart: Int, anchorEnd: Int
    ) -> (start: Int, end: Int) {
        guard var (start, end) = try? trimmed(text, baseStart, baseEnd) else { return (baseStart, baseStart - 1) }
        if start > end || end - start + 1 <= quoteMax {
            return (start, end)
        }
        if anchorEnd - start + 1 <= quoteMax {
            end = start + quoteMax - 1
        } else {
            start = anchorEnd - quoteMax + 1
            if let space = text.firstIndex(of: " ", from: start, to: anchorStart) {
                start = space + 1
            }
            end = min(baseEnd, anchorEnd + (quoteMax - (anchorEnd - start + 1)))
        }
        // 단어 중간에서 끊기지 않게
        if let space = text.lastIndex(of: " ", from: anchorEnd + 1, to: end + 1) {
            end = space - 1
        }
        return (try? trimmed(text, start, end)) ?? (start, start - 1)
    }

    static func word(_ text: ScalarText, at index: Int) throws -> String {
        var start = index
        var end = index
        while start > 0, try !text.checked(start - 1).isPythonSpace {
            start -= 1
        }
        while end < text.count - 1, try !text.checked(end + 1).isPythonSpace {
            end += 1
        }
        return text.string(from: start, to: end + 1).pythonStripped { !$0.isPythonWord }
    }

    static func focus(_ text: ScalarText, _ event: Event) throws -> FeedbackCandidate.Focus {
        if event.kind == .pace, let base = event.base {
            let range = try trimmed(text, base.start, base.end)
            return FeedbackCandidate.Focus(phrase: flattened(text.string(from: range.start, to: range.end + 1)))
        }
        var index = event.anchorEnd
        while index > 0, try text.checked(index).isPythonSpace {
            index -= 1
        }
        guard event.kind.isGap else {
            return FeedbackCandidate.Focus(
                char: String(scalars: [try text.checked(index)]), word: try word(text, at: index)
            )
        }
        var next = index + 1
        // 단어 중간이면 그 단어 끝까지 건너뛴다
        while next < text.count, try !text.checked(next).isPythonSpace {
            next += 1
        }
        while next < text.count, try text.checked(next).isPythonSpace {
            next += 1
        }
        return FeedbackCandidate.Focus(
            wordBefore: try word(text, at: index), wordAfter: next < text.count ? try word(text, at: next) : ""
        )
    }

    static func playRange(
        _ syllables: [Syllable], start: Int, end: Int, extendAfter: Int?, durationMs: Int
    ) -> (start: Int, end: Int)? {
        let inside = syllables.filter { start <= $0.idx && $0.idx <= end }
        guard var startMs = inside.map(\.startMs).min(), var endMs = inside.map(\.endMs).max() else { return nil }
        // 쉼은 쉰 뒤 첫 글자까지 들려준다
        if let extendAfter, let after = syllables.first(where: { $0.idx > extendAfter }) {
            endMs = max(endMs, after.endMs)
        }
        startMs = max(0, startMs)
        endMs = durationMs > 0 ? min(durationMs, endMs) : endMs
        return endMs > startMs ? (startMs, endMs) : nil
    }

    static func flattened(_ text: String) -> String {
        String(scalars: text.unicodeScalars.map { $0 == "\n" ? " " : $0 })
    }
}
