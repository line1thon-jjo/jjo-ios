//
//  UtteranceLayoutTests.swift
//  jjo-ios-Tests
//
//  Created by dohyeoplim on 11/16/26.
//

import CoreGraphics
import Testing
@testable import jjo_ios

struct UtteranceLayoutTests {
    private typealias Metrics = UtteranceMetrics

    private func layout(_ utterance: UtteranceAnalysis, width: CGFloat) -> UtteranceLayout {
        UtteranceLayout.make(tokens: GlyphBuilder.groupWords(GlyphBuilder.build(utterance)), width: width) { scalar in
            scalar == " " ? GlyphWidth(regular: 5, heavy: 5) : GlyphWidth(regular: 18, heavy: 19)
        }
    }

    private func plain(_ text: String) -> UtteranceAnalysis {
        UtteranceAnalysis(
            spokenText: text, marks: [], paces: [], pauses: [], segments: [], replaced: [], added: [], skipped: []
        )
    }

    private func texts(_ layout: UtteranceLayout) -> [String] {
        layout.lines.map { String(scalars: $0.items.map(\.glyph.scalar)) }
    }

    @Test func wrapsWords() {
        let result = layout(plain("가나다 라마 바사아"), width: 100)
        #expect(texts(result) == ["가나다 라마 ", "바사아"])
        #expect(result.lines[0].items.last?.advance == 0)
        #expect(result.height == Metrics.lineHeight * 2)
    }

    @Test func breaksLines() {
        let result = layout(plain("가\n\n 나\n"), width: 200)
        #expect(texts(result) == ["가", "", " 나"])
        #expect(result.lines[2].items[0].advance == 0)
        #expect(result.lines[2].items[1].x == 0)
        #expect(result.glyphCount == 6)
    }

    @Test func collapsesSpaces() {
        let result = layout(plain("가  나"), width: 200)
        let advances = result.lines[0].items.map(\.advance)
        #expect(advances[1] == 5 + Metrics.tracking)
        #expect(advances[2] == 0)
    }

    @Test func splitsLongWord() {
        let result = layout(plain("가나다라마바사"), width: 60)
        #expect(texts(result) == ["가나다", "라마바", "사"])
    }

    @Test func appliesPaceSpacing() {
        var utterance = plain("가나다")
        utterance.paces = [.init(startIdx: 0, endIdx: 1, label: .slow)]
        let items = layout(utterance, width: 200).lines[0].items
        #expect(abs(items[0].boxWidth - (19 + Metrics.tracking + Metrics.slowSpacing)) < 0.0001)
        #expect(items[1].boxWidth == 19 + Metrics.tracking)
        #expect(abs(items[2].x - (items[0].boxWidth + items[1].boxWidth)) < 0.0001)
    }

    @Test func reservesStretchAndPause() {
        var utterance = plain("가나")
        utterance.marks = [.init(idx: 0, stretch: 2.5)]
        utterance.pauses = [.init(afterIdx: 0, durationMs: 1500)]
        let item = layout(utterance, width: 400).lines[0].items[0]
        let stretch = Metrics.visualStretch(2.5)
        #expect(abs(stretch - 1.495) < 0.0001)
        #expect(item.pauseWidth == Metrics.fontSize * 3)
        #expect(item.advance == item.boxWidth + (stretch - 1) * Metrics.stretchMargin + item.pauseWidth)
        #expect(item.pauseX == item.x + item.advance - item.pauseWidth)
    }

    @Test func clampsMetrics() {
        #expect(Metrics.visualStretch(0.8) == 1)
        #expect(Metrics.visualStretch(9) == 2)
        #expect(Metrics.pauseWidth(0) == 0)
        #expect(Metrics.pauseWidth(400) == Metrics.pauseMinWidth)
        #expect(Metrics.pauseWidth(9000) == Metrics.fontSize * 4)
    }

    @Test func hitTestsGlyph() {
        let result = layout(plain("가나 다라마바"), width: 60)
        #expect(result.glyph(at: CGPoint(x: 20, y: 10))?.char == "나")
        #expect(result.glyph(at: CGPoint(x: 5, y: Metrics.lineHeight + 1))?.char == "다")
        #expect(result.glyph(at: CGPoint(x: 5, y: Metrics.lineHeight * 9)) == nil)
        #expect(result.lineIndex(containing: 5) == 1)
    }

    @Test func introSettles() {
        let start = UtteranceIntro(elapsed: 0, glyphCount: 100)
        #expect(start.stepMs == 4)
        #expect(start.transform(0) == 0)
        #expect(start.sweep(0) == 0)
        #expect(UtteranceIntro(elapsed: 0, glyphCount: 1400).stepMs == 1)

        let middle = UtteranceIntro(elapsed: 0.2245, glyphCount: 100)
        #expect(abs(middle.sweep(0) - 1) < 0.001)
        #expect(middle.underline(0) == 1)
        #expect(middle.isWeightSettled(0))
        #expect(!middle.isWeightSettled(1))

        #expect(UtteranceIntro.settled.transform(1499) == 1)
        #expect(UtteranceIntro.settled.emphasis(1499) == 1)
        #expect(UtteranceIntro.settled.sweep(1499) == 0)
        #expect(UtteranceIntro.settled.pauseLabelScale(1499) == 1)
    }
}
