//
//  UtteranceTextView.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

struct UtteranceTextView: View {
    let content: ReportContent
    let playing: PlaybackRange?
    let currentChar: Int
    let focusPace: UtteranceAnalysis.PaceLabel?
    let introStart: Date?
    let scrollProxy: ScrollViewProxy
    var onSelectSegment: ((Int) -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var width: CGFloat = 0
    @State private var layout: UtteranceLayout?
    @State private var isSettled = false

    private struct LineID: Hashable {
        let index: Int
    }

    private struct FocusKey: Equatable {
        let pace: UtteranceAnalysis.PaceLabel?
        let isReady: Bool
    }

    private var playingSegment: Int {
        guard currentChar >= 0, case .segment(let index) = playing?.source else { return -1 }
        return index
    }

    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(layout?.lines ?? []) { line in
                UtteranceLineView(
                    line: line,
                    glyphCount: content.glyphCount,
                    focusPace: focusPace,
                    playingSegment: line.items.contains { $0.glyph.segment == playingSegment } ? playingSegment : -1,
                    currentChar: (line.firstIdx...line.lastIdx + 2).contains(currentChar) ? currentChar : -1,
                    introStart: isSettled ? nil : introStart
                )
                .equatable()
                .id(LineID(index: line.id))
            }
        }
        .frame(maxWidth: .infinity, minHeight: UtteranceMetrics.lineHeight, alignment: .topLeading)
        .contentShape(Rectangle())
        .gesture(SpatialTapGesture().onEnded { select(at: $0.location) }, isEnabled: onSelectSegment != nil)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        .task(id: width) { relayout() }
        .task(id: introStart) { await settle() }
        .task(id: FocusKey(pace: focusPace, isReady: layout != nil)) { scrollToFocus() }
        .accessibilityRepresentation { narration }
    }

    private var narration: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(content.narration) { passage in
                if let onSelectSegment, passage.segment >= 0 {
                    Button(passage.label) { onSelectSegment(passage.segment) }
                        .accessibilityHint("이 부분 듣기")
                } else {
                    Text(passage.label)
                }
            }
        }
    }

    private func relayout() {
        guard width > 0 else { return }
        let measurer = GlyphMeasurer.shared
        layout = UtteranceLayout.make(tokens: content.tokens, width: width) { measurer.width(of: $0) }
    }

    private func settle() async {
        guard let introStart, !reduceMotion else {
            isSettled = true
            return
        }
        let remaining = UtteranceIntro.duration - Date.now.timeIntervalSince(introStart)
        isSettled = remaining <= 0
        guard remaining > 0 else { return }
        try? await Task.sleep(for: .seconds(remaining))
        if !Task.isCancelled {
            isSettled = true
        }
    }

    private func scrollToFocus() {
        guard let focusPace, let index = layout?.firstLine(with: focusPace) else { return }
        withAnimation(reduceMotion ? nil : .smooth) {
            scrollProxy.scrollTo(LineID(index: index), anchor: .center)
        }
    }

    private func select(at location: CGPoint) {
        guard let glyph = layout?.glyph(at: location), glyph.segment >= 0 else { return }
        Haptics.select()
        onSelectSegment?(glyph.segment)
    }
}
