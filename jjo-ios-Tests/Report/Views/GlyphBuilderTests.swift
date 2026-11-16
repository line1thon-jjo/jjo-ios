//
//  GlyphBuilderTests.swift
//  jjo-ios-Tests
//
//  Created by dohyeoplim on 11/16/26.
//

import Testing
@testable import jjo_ios

struct GlyphBuilderTests {
    private func utterance(
        _ text: String,
        marks: [UtteranceAnalysis.Mark] = [],
        paces: [UtteranceAnalysis.Pace] = [],
        pauses: [UtteranceAnalysis.NotablePause] = [],
        segments: [UtteranceAnalysis.Segment] = [],
        replaced: [UtteranceAnalysis.Replaced] = [],
        added: [UtteranceAnalysis.Added] = [],
        skipped: [UtteranceAnalysis.Skipped] = []
    ) -> UtteranceAnalysis {
        UtteranceAnalysis(
            spokenText: text, marks: marks, paces: paces, pauses: pauses, segments: segments,
            replaced: replaced, added: added, skipped: skipped
        )
    }

    @Test func mapsPitchLevels() {
        let marks = [1, 2, 3, 6, 7].enumerated().map { UtteranceAnalysis.Mark(idx: $0.offset, pitch: $0.element) }
        let glyphs = GlyphBuilder.build(utterance("가나다라마바", marks: marks))
        #expect(glyphs.map(\.pitch) == [-2, -1, 0, 1, 2, 0])
        #expect(glyphs.map(\.isEmphasized) == [true, true, false, true, true, false])
    }

    @Test func ignoresOutOfRange() {
        let glyphs = GlyphBuilder.build(utterance(
            "가나",
            marks: [.init(idx: -1, pitch: 7), .init(idx: 2, stretch: 3)],
            paces: [.init(startIdx: -3, endIdx: 9, label: .fast)],
            pauses: [.init(afterIdx: 5, durationMs: 800)]
        ))
        #expect(glyphs.map(\.pitch) == [0, 0])
        #expect(glyphs.map(\.stretch) == [1, 1])
        #expect(glyphs.map(\.pace) == [.fast, .fast])
        #expect(glyphs.map(\.pauseMs) == [0, 0])
    }

    @Test func marksPaceEnd() {
        let glyphs = GlyphBuilder.build(utterance(
            "가나다라마",
            paces: [.init(startIdx: 0, endIdx: 1, label: .fast), .init(startIdx: 2, endIdx: 3, label: .slow)]
        ))
        #expect(glyphs.map(\.paceEnd) == [false, true, false, true, false])
        #expect(GlyphBuilder.build(utterance("가", paces: [.init(startIdx: 0, endIdx: 0, label: .slow)]))[0].paceEnd)
    }

    @Test func skippedClearsMarks() {
        let glyphs = GlyphBuilder.build(utterance(
            "가나다",
            marks: [.init(idx: 1, pitch: 7, stretch: 2.5)],
            replaced: [.init(startIdx: 0, endIdx: 1, spoken: "가나", scriptText: "거너")],
            added: [.init(startIdx: 2, endIdx: 2, spoken: "다")],
            skipped: [.init(startIdx: 1, endIdx: 1)]
        ))
        #expect(glyphs.map(\.diff) == [.replaced, .skipped, .added])
        #expect(glyphs[1].pitch == 0)
        #expect(glyphs[1].stretch == 1)
    }

    @Test func indexesByScalar() {
        let text = "가\u{1F600}e\u{301}나"
        let glyphs = GlyphBuilder.build(utterance(
            text,
            marks: [.init(idx: 4, pitch: 6)],
            pauses: [.init(afterIdx: 1, durationMs: 500)],
            segments: [.init(startIdx: 2, endIdx: 4, startMs: 0, endMs: 900)]
        ))
        #expect(glyphs.count == 5)
        #expect(glyphs[1].pauseMs == 500)
        #expect(glyphs[4].char == "나")
        #expect(glyphs[4].pitch == 1)
        #expect(glyphs.map(\.segment) == [-1, -1, 0, 0, 0])
    }

    @Test func findsCharAtTime() {
        let segments: [UtteranceAnalysis.Segment] = [
            .init(startIdx: 0, endIdx: 3, startMs: 100, endMs: 500),
            .init(startIdx: 4, endIdx: 4, startMs: 700, endMs: 800)
        ]
        #expect(GlyphBuilder.findSegment(segments, at: 99) == -1)
        #expect(GlyphBuilder.findSegment(segments, at: 500) == -1)
        #expect(GlyphBuilder.findChar(segments, at: 100) == 0)
        #expect(GlyphBuilder.findChar(segments, at: 299.9) == 1)
        #expect(GlyphBuilder.findChar(segments, at: 499.9) == 3)
        #expect(GlyphBuilder.findChar(segments, at: 600) == -1)
        #expect(GlyphBuilder.findChar(segments, at: 799) == 4)
    }

    @Test func groupsWords() {
        let tokens = GlyphBuilder.groupWords(GlyphBuilder.build(utterance("가나 다\n라  ")))
        let kinds = tokens.map { token in
            switch token {
            case .word(let glyphs): String(scalars: glyphs.map(\.scalar))
            case .space: "_"
            case .lineBreak: "/"
            }
        }
        #expect(kinds == ["가나", "_", "다", "/", "라", "_", "_"])
    }
}
