//
//  UtteranceLineView.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

struct UtteranceLineView: View, Equatable {
    let line: UtteranceLayout.Line
    let glyphCount: Int
    let focusPace: UtteranceAnalysis.PaceLabel?
    let playingSegment: Int
    let currentChar: Int
    let introStart: Date?

    private typealias Metrics = UtteranceMetrics

    var body: some View {
        if let introStart {
            TimelineView(.animation) { timeline in
                canvas(UtteranceIntro(elapsed: timeline.date.timeIntervalSince(introStart), glyphCount: glyphCount))
            }
        } else {
            canvas(.settled)
        }
    }

    private func canvas(_ intro: UtteranceIntro) -> some View {
        Canvas { context, _ in
            for item in line.items where item.advance > 0 {
                draw(item, in: context, intro: intro)
            }
        }
        .frame(height: Metrics.lineHeight)
        .accessibilityHidden(true)
    }

    private func draw(_ item: UtteranceLayout.Item, in context: GraphicsContext, intro: UtteranceIntro) {
        var context = context
        let glyph = item.glyph

        if let focusPace, glyph.pace != focusPace {
            context.opacity = Metrics.focusDimOpacity
        }
        if glyph.segment >= 0, glyph.segment == playingSegment {
            let highlight = CGRect(
                x: item.x, y: Metrics.contentTop, width: item.advance, height: Metrics.highlightHeight
            )
            context.fill(Path(highlight), with: .color(.lime.opacity(0.45)))
        }
        if let pace = glyph.pace {
            let underline = CGRect(
                x: item.x, y: Metrics.underlineTop, width: item.advance * intro.underline(glyph.idx), height: 2
            )
            context.fill(Path(underline), with: .color(Self.paceColor(pace)))
        }

        guard glyph.scalar != " " else { return }
        drawChar(item, in: context, intro: intro)
        if item.pauseWidth > 0 {
            drawPause(item, in: context, intro: intro)
        }
    }

    private func drawChar(_ item: UtteranceLayout.Item, in context: GraphicsContext, intro: UtteranceIntro) {
        var context = context
        let glyph = item.glyph
        let reveal = intro.transform(glyph.idx)
        let wave = wave(of: glyph.idx)
        let emphasis = glyph.isEmphasized ? intro.emphasis(glyph.idx) : 0

        let weight: Pretendard = switch wave {
        case 0: .bold
        case 1: .semiBold
        case 2: .medium
        default: glyph.isEmphasized && intro.isWeightSettled(glyph.idx) ? .semiBold : .regular
        }
        let color = wave == nil ? Self.inkColor(emphasis) : Color.ink

        context.translateBy(x: item.x, y: -CGFloat(glyph.pitch) * Metrics.pitchStep * reveal)
        context.scaleBy(x: 1 + (item.stretch - 1) * reveal, y: 1)
        if glyph.diff == .skipped {
            context.opacity *= Metrics.skippedOpacity
        }
        if glyph.diff == .added {
            let block = CGRect(x: 0, y: 0, width: item.boxWidth, height: Metrics.lineHeight)
            context.fill(Path(block), with: .color(.ink.opacity(0.06)))
        }

        drawText(glyph.char, weight: weight, color: color, width: item.contentWidth, in: context)

        let sweep = intro.sweep(glyph.idx)
        if sweep > 0 {
            var overlay = context
            overlay.opacity *= sweep
            drawText(glyph.char, weight: .bold, color: .ink, width: item.contentWidth, in: overlay)
        }

        switch glyph.diff {
        case .replaced:
            var line = Path()
            line.move(to: CGPoint(x: 0.75, y: Metrics.baseline + Metrics.fontSize * 0.3 + 0.75))
            line.addLine(to: CGPoint(x: item.boxWidth, y: Metrics.baseline + Metrics.fontSize * 0.3 + 0.75))
            context.stroke(
                line, with: .color(color), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [0.01, 3])
            )
        case .skipped:
            let strike = CGRect(
                x: 0, y: Metrics.baseline - Metrics.fontSize * 0.29, width: item.boxWidth, height: 1.5
            )
            context.fill(Path(strike), with: .color(color))
        case .added, nil:
            break
        }
    }

    private func drawText(
        _ char: String, weight: Pretendard, color: Color, width: CGFloat, in context: GraphicsContext
    ) {
        let text = Text(char)
            .font(.custom(weight.rawValue, fixedSize: Metrics.fontSize))
            .foregroundStyle(color)
        let resolved = context.resolve(text)
        let size = resolved.measure(in: CGSize(width: CGFloat.infinity, height: .infinity))
        let baseline = resolved.firstBaseline(in: size)
        context.draw(
            resolved, at: CGPoint(x: (width - size.width) / 2, y: Metrics.baseline - baseline), anchor: .topLeading
        )
    }

    private func drawPause(_ item: UtteranceLayout.Item, in context: GraphicsContext, intro: UtteranceIntro) {
        let idx = item.glyph.idx
        let inset = Metrics.fontSize * 0.2
        let lineY = Metrics.pauseTop + Metrics.fontSize * 0.62 + 1
        let lineWidth = (item.pauseWidth - inset * 2) * intro.pauseLine(idx)

        if lineWidth > 2 {
            let fullWidth = item.pauseWidth - inset * 2 - 2
            let gap = fullWidth / (fullWidth / 4).rounded()
            var dots = Path()
            dots.move(to: CGPoint(x: item.pauseX + inset + 1, y: lineY))
            dots.addLine(to: CGPoint(x: item.pauseX + inset + lineWidth - 1, y: lineY))
            context.stroke(
                dots,
                with: .color(.ink.opacity(0.7)),
                style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [0.001, gap - 0.001])
            )
        }

        let opacity = intro.pauseLabelOpacity(idx)
        guard opacity > 0 else { return }

        let label = context.resolve(
            Text(ReportCopy.pause(item.glyph.pauseMs))
                .font(.custom(Pretendard.semiBold.rawValue, fixedSize: 12))
                .foregroundStyle(Color.textCharcoal)
        )
        let textSize = label.measure(in: CGSize(width: CGFloat.infinity, height: .infinity))
        let size = CGSize(width: textSize.width + 10, height: 12 * 1.2 + 4)
        let bottom = CGPoint(x: item.pauseX + item.pauseWidth / 2, y: Metrics.pauseTop + Metrics.fontSize * 0.48)
        let scale = intro.pauseLabelScale(idx)

        var context = context
        context.opacity *= opacity
        context.translateBy(x: bottom.x, y: bottom.y)
        context.scaleBy(x: scale, y: scale)
        let chip = CGRect(x: -size.width / 2, y: -size.height, width: size.width, height: size.height)
        context.fill(Path(roundedRect: chip, cornerRadius: 6), with: .color(.surfaceChip))
        context.draw(label, at: CGPoint(x: 0, y: -size.height / 2), anchor: .center)
    }

    private func wave(of idx: Int) -> Int? {
        let distance = currentChar - idx
        return currentChar >= 0 && distance >= 0 && distance < 3 ? distance : nil
    }

    private static func paceColor(_ pace: UtteranceAnalysis.PaceLabel) -> Color {
        switch pace {
        case .fast: .paceFast.opacity(0.8)
        case .slow: .paceSlow.opacity(0.7)
        }
    }

    private static func inkColor(_ emphasis: Double) -> Color {
        if emphasis <= 0 { return .textGlyphMuted }
        if emphasis >= 1 { return .ink }
        return Color(
            .sRGB,
            red: mix(0x9A, 0x09, emphasis),
            green: mix(0x9A, 0x09, emphasis),
            blue: mix(0x9E, 0x0B, emphasis)
        )
    }

    private static func mix(_ from: Double, _ to: Double, _ amount: Double) -> Double {
        (from + (to - from) * amount) / 255
    }
}
