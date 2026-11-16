//
//  TimedWord.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated struct TimedWord: Equatable, Sendable {
    var text: String
    var start: PyNumber
    var end: PyNumber
    var prob: Double

    var hangul: [Unicode.Scalar] { text.unicodeScalars.filter(\.isHangulSyllable) }

    var hangulCount: Int { text.unicodeScalars.count(where: \.isHangulSyllable) }

    init(_ word: WordTiming) {
        text = word.text
        start = PyNumber(word.start)
        end = PyNumber(word.end)
        prob = word.prob
    }
}
