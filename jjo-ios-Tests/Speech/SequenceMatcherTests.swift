//
//  SequenceMatcherTests.swift
//  jjo-ios-Tests
//
//  Created by dohyeoplim on 11/16/26.
//

import Testing
@testable import jjo_ios

struct SequenceMatcherTests {
    private func blocks(_ a: String, _ b: String) -> [[Int]] {
        SequenceMatcher(a: Array(a.unicodeScalars), b: Array(b.unicodeScalars))
            .matchingBlocks()
            .map { [$0.a, $0.b, $0.size] }
    }

    @Test func matchesDifflib() {
        #expect(blocks("abxcd", "abcd") == [[0, 0, 2], [3, 2, 2], [5, 4, 0]])
        #expect(blocks("qabxcd", "abycdf") == [[1, 0, 2], [4, 3, 2], [6, 6, 0]])
        #expect(blocks("", "가나") == [[0, 2, 0]])
    }

    @Test func breaksTiesLikeDifflib() {
        #expect(blocks("가나가나다", "나가나") == [[1, 0, 3], [5, 3, 0]])
        #expect(blocks("나다가나다라", "가나다가나다") == [[0, 1, 5], [6, 6, 0]])
        #expect(blocks("가가나가", "가나나가가") == [[0, 3, 2], [4, 5, 0]])
    }
}
