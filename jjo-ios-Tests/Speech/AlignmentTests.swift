//
//  AlignmentTests.swift
//  jjo-ios-Tests
//
//  Created by dohyeoplim on 11/16/26.
//

import Testing
@testable import jjo_ios

struct AlignmentTests {
    private let units = ScriptText.parse("저는 오늘 발표를 합니다")

    private func align(_ words: [WordTiming]) -> [TimedSyllable] {
        Alignment.alignWords(units: units, words: words.map(TimedWord.init))
    }

    private func unaligned(_ syllables: [TimedSyllable]) -> String {
        syllables.filter { !$0.aligned }.map(\.unit.char).text
    }

    @Test func marksSkipped() {
        let syllables = align([
            WordTiming(text: "저는", start: 0.0, end: 0.4),
            WordTiming(text: "발표를", start: 0.5, end: 1.1),
            WordTiming(text: "합니다", start: 1.2, end: 1.8),
        ])
        #expect(unaligned(syllables) == "오늘")
        let starts = syllables.map(\.startMs.value)
        #expect(starts == starts.sorted())
    }

    @Test func keepsZeroLength() {
        let syllables = align([
            WordTiming(text: "저는", start: 0.0, end: 0.4),
            WordTiming(text: "오늘", start: 0.5, end: 0.9),
            WordTiming(text: "발표를", start: 1.0, end: 1.0),
            WordTiming(text: "합니다", start: 1.2, end: 1.8),
        ])
        #expect(syllables.allSatisfy { $0.aligned })
        let starts = syllables.map(\.startMs.value)
        #expect(starts == starts.sorted())
        #expect(syllables[4].endMs.value <= syllables[7].startMs.value)
    }

    @Test func keepsZeroRuns() {
        let syllables = align([
            WordTiming(text: "저는", start: 0.0, end: 0.4),
            WordTiming(text: "오늘", start: 0.5, end: 0.5),
            WordTiming(text: "발표를", start: 0.5, end: 0.5),
            WordTiming(text: "합니다", start: 1.2, end: 1.8),
        ])
        #expect(syllables.allSatisfy { $0.aligned })
        #expect(syllables.allSatisfy { $0.endMs.value >= $0.startMs.value })
    }

    @Test func ignoresSingleAnchor() {
        let syllables = align([
            WordTiming(text: "저는", start: 0.0, end: 0.4),
            WordTiming(text: "늘", start: 0.5, end: 0.7),
            WordTiming(text: "합니다", start: 1.2, end: 1.8),
        ])
        #expect(unaligned(syllables) == "오늘발표를")
    }

    @Test func carriesProbability() {
        let syllables = align([
            WordTiming(text: "저는", start: 0.0, end: 0.4, prob: 0.95),
            WordTiming(text: "오늘", start: 0.5, end: 0.9, prob: 0.3),
            WordTiming(text: "발표를", start: 1.0, end: 1.5),
            WordTiming(text: "합니다", start: 1.6, end: 2.2),
        ])
        #expect(syllables[0].confidence == 0.95)
        #expect(syllables[2].confidence == 0.3 && syllables[3].confidence == 0.3)
    }

    @Test func splitsAtDips() {
        var cost = [Double](repeating: 1, count: 50)
        cost[10] = 0.2
        cost[20] = 0.2
        let bounds = AlignmentRefinement.splitByEnergy(cost[...], weights: [1, 1, 1], lambda: 0.3)
        #expect(bounds.count == 4 && abs(bounds[1] - 10) <= 1 && abs(bounds[2] - 20) <= 1)
    }

    @Test func retimesDegenerate() {
        let db = EnergyCurve.make([(20, -70), (60, -20), (20, -70), (60, -20), (20, -70)])
        let words = [
            WordTiming(text: "가나다", start: 0.2, end: 0.8, prob: 0.9),
            WordTiming(text: "라마", start: 1.6, end: 1.6, prob: 0.9),
        ]
        let out = WordRetiming.retimeDegenerate(words.map(TimedWord.init), db: db, config: .default)
        #expect(out[1].end.value - out[1].start.value >= 0.1)
        #expect(out[1].start.value >= out[0].end.value - 1e-6)
        #expect((1.0...1.3).contains(out[1].start.value))
        #expect(abs(out[1].end.value - 1.6) <= 0.03)
    }
}

nonisolated enum EnergyCurve {
    static func make(_ parts: [(frames: Int, db: Double)]) -> [Double] {
        parts.flatMap { [Double](repeating: $0.db, count: $0.frames) }
    }
}
