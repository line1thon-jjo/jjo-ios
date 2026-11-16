//
//  UtteranceLayout.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import CoreGraphics

nonisolated struct UtteranceLayout: Equatable, Sendable {
    nonisolated struct Item: Equatable, Sendable {
        var glyph: Glyph
        var x: CGFloat
        var boxWidth: CGFloat
        var contentWidth: CGFloat
        var stretch: CGFloat
        var pauseWidth: CGFloat
        var advance: CGFloat

        var pauseX: CGFloat { x + advance - pauseWidth }
        var maxX: CGFloat { x + advance }
    }

    nonisolated struct Line: Equatable, Sendable, Identifiable {
        var id: Int
        var items: [Item]

        var firstIdx: Int { items.first?.glyph.idx ?? -1 }
        var lastIdx: Int { items.last?.glyph.idx ?? -1 }
    }

    var lines: [Line]
    var width: CGFloat
    var glyphCount: Int

    var height: CGFloat { CGFloat(lines.count) * UtteranceMetrics.lineHeight }

    static func make(
        tokens: [GlyphToken], width: CGFloat, measure: (Unicode.Scalar) -> GlyphWidth
    ) -> UtteranceLayout {
        var lines: [Line] = []
        var items: [Item] = []
        var cursor: CGFloat = 0
        var glyphCount = 0

        func closeLine() {
            // 줄 끝에 걸린 공백은 웹에서처럼 너비 없이 접는다
            if let last = items.last, last.glyph.scalar == " " {
                items[items.count - 1].boxWidth = 0
                items[items.count - 1].advance = 0
            }
            lines.append(Line(id: lines.count, items: items))
            items = []
            cursor = 0
        }

        func place(_ item: Item) {
            var item = item
            item.x = cursor
            items.append(item)
            cursor += item.advance
        }

        for token in tokens {
            switch token {
            case .lineBreak:
                glyphCount += 1
                closeLine()
            case .space(let glyph):
                glyphCount += 1
                let isCollapsed = items.isEmpty || items.last?.glyph.scalar == " "
                let spaceWidth = measure(glyph.scalar).regular + UtteranceMetrics.tracking
                    + UtteranceMetrics.paceSpacing(glyph.pace)
                let advance = isCollapsed ? 0 : max(0, spaceWidth)
                place(Item(
                    glyph: glyph, x: 0, boxWidth: advance, contentWidth: 0, stretch: 1, pauseWidth: 0, advance: advance
                ))
            case .word(let glyphs):
                glyphCount += glyphs.count
                let word = glyphs.map { item(for: $0, measure: measure) }
                let wordWidth = word.reduce(0) { $0 + $1.advance }
                if !items.isEmpty, cursor + wordWidth > width + 0.01 {
                    closeLine()
                }
                for item in word {
                    // 한 줄보다 긴 단어는 화면 밖으로 나가지 않게 글자 단위로 넘긴다
                    if wordWidth > width, !items.isEmpty, cursor + item.advance > width + 0.01 {
                        closeLine()
                    }
                    place(item)
                }
            }
        }
        if !items.isEmpty {
            closeLine()
        }

        return UtteranceLayout(lines: lines, width: width, glyphCount: glyphCount)
    }

    func lineIndex(containing idx: Int) -> Int? {
        lines.firstIndex { line in line.items.contains { $0.glyph.idx == idx } }
    }

    func firstLine(with pace: UtteranceAnalysis.PaceLabel) -> Int? {
        lines.firstIndex { line in line.items.contains { $0.glyph.pace == pace } }
    }

    func glyph(at point: CGPoint) -> Glyph? {
        let index = Int((point.y / UtteranceMetrics.lineHeight).rounded(.down))
        guard lines.indices.contains(index) else { return nil }
        return lines[index].items.first { $0.advance > 0 && point.x >= $0.x && point.x < $0.maxX }?.glyph
    }

    private static func item(for glyph: Glyph, measure: (Unicode.Scalar) -> GlyphWidth) -> Item {
        let measured = measure(glyph.scalar)
        let spacing = UtteranceMetrics.tracking + (glyph.paceEnd ? 0 : UtteranceMetrics.paceSpacing(glyph.pace))
        let stretch = UtteranceMetrics.visualStretch(glyph.stretch)
        let boxWidth = max(0, measured.box + spacing)
        let pauseWidth = UtteranceMetrics.pauseWidth(glyph.pauseMs)
        return Item(
            glyph: glyph,
            x: 0,
            boxWidth: boxWidth,
            contentWidth: measured.box,
            stretch: stretch,
            pauseWidth: pauseWidth,
            advance: boxWidth + (stretch - 1) * UtteranceMetrics.stretchMargin + pauseWidth
        )
    }
}
