//
//  GlyphBuilder.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated enum GlyphBuilder {
    private static let pitchLevels = [1: -2, 2: -1, 6: 1, 7: 2]

    static func build(_ utterance: UtteranceAnalysis) -> [Glyph] {
        let scalars = ScalarText(utterance.spokenText).scalars
        let count = scalars.count

        var pitch = [Int](repeating: 0, count: count)
        var stretch = [Double](repeating: 1, count: count)
        var pace = [UtteranceAnalysis.PaceLabel?](repeating: nil, count: count)
        var diff = [Glyph.Difference?](repeating: nil, count: count)
        var segment = [Int](repeating: -1, count: count)
        let pauseAfter = Dictionary(
            utterance.pauses.map { ($0.afterIdx, $0.durationMs) }, uniquingKeysWith: { _, last in last }
        )

        for mark in utterance.marks where scalars.indices.contains(mark.idx) {
            if let level = mark.pitch, level != 0 {
                pitch[mark.idx] = pitchLevels[level] ?? 0
            }
            if let ratio = mark.stretch, ratio != 0 {
                stretch[mark.idx] = ratio
            }
        }

        utterance.paces.forEach { fill(&pace, $0.startIdx, $0.endIdx, $0.label) }
        utterance.replaced.forEach { fill(&diff, $0.startIdx, $0.endIdx, .replaced) }
        utterance.added.forEach { fill(&diff, $0.startIdx, $0.endIdx, .added) }
        utterance.skipped.forEach { fill(&diff, $0.startIdx, $0.endIdx, .skipped) }
        for (index, range) in utterance.segments.enumerated() {
            fill(&segment, range.startIdx, range.endIdx, index)
        }

        return scalars.enumerated().map { idx, scalar in
            let isSkipped = diff[idx] == .skipped
            let next = idx + 1 < count ? pace[idx + 1] : nil
            return Glyph(
                idx: idx,
                scalar: scalar,
                pitch: isSkipped ? 0 : pitch[idx],
                stretch: isSkipped ? 1 : stretch[idx],
                pace: pace[idx],
                paceEnd: pace[idx] != nil && next != pace[idx],
                pauseMs: pauseAfter[idx] ?? 0,
                diff: diff[idx],
                segment: segment[idx]
            )
        }
    }

    static func findSegment(_ segments: [UtteranceAnalysis.Segment], at timeMs: Double) -> Int {
        segments.firstIndex { timeMs >= Double($0.startMs) && timeMs < Double($0.endMs) } ?? -1
    }

    static func findChar(_ segments: [UtteranceAnalysis.Segment], at timeMs: Double) -> Int {
        let index = findSegment(segments, at: timeMs)
        guard index >= 0 else { return -1 }

        let segment = segments[index]
        let progress = (timeMs - Double(segment.startMs)) / Double(segment.endMs - segment.startMs)
        let offset = Int((progress * Double(segment.endIdx - segment.startIdx + 1)).rounded(.down))
        return min(segment.endIdx, segment.startIdx + offset)
    }

    static func groupWords(_ glyphs: [Glyph]) -> [GlyphToken] {
        var tokens: [GlyphToken] = []
        var word: [Glyph] = []

        for glyph in glyphs {
            if glyph.scalar == "\n" || glyph.scalar == " " {
                if !word.isEmpty {
                    tokens.append(.word(word))
                    word = []
                }
                tokens.append(glyph.scalar == "\n" ? .lineBreak(glyph) : .space(glyph))
            } else {
                word.append(glyph)
            }
        }
        if !word.isEmpty {
            tokens.append(.word(word))
        }
        return tokens
    }

    private static func fill<Value>(_ target: inout [Value], _ start: Int, _ end: Int, _ value: Value) {
        let lower = max(0, start)
        let upper = min(end, target.count - 1)
        guard lower <= upper else { return }
        for idx in lower...upper {
            target[idx] = value
        }
    }
}
