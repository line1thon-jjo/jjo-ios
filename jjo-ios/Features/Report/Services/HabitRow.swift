//
//  HabitRow.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated struct HabitRow: Equatable, Sendable, Identifiable {
    var id: String
    var label: String
    var unit: String
    var pace: UtteranceAnalysis.PaceLabel?
    var after: Int
    var before: Int?

    var isCleared: Bool { after == 0 }

    var difference: Int? { before.map { after - $0 } }
}
