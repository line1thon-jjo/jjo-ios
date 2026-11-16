//
//  PitchCandidateTable.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated struct PitchCandidateTable: Sendable {
    let capacity: Int
    var counts: [Int]
    var intensities: [Double]
    var frequencies: [Double]
    var strengths: [Double]

    init(frameCount: Int, capacity: Int) {
        self.capacity = capacity
        counts = Array(repeating: 0, count: frameCount)
        intensities = Array(repeating: 0, count: frameCount)
        frequencies = Array(repeating: 0, count: frameCount * capacity)
        strengths = Array(repeating: 0, count: frameCount * capacity)
    }

    init(joining chunks: [PitchCandidateTable], capacity: Int) {
        self.capacity = capacity
        counts = chunks.flatMap(\.counts)
        intensities = chunks.flatMap(\.intensities)
        frequencies = chunks.flatMap(\.frequencies)
        strengths = chunks.flatMap(\.strengths)
    }
}
