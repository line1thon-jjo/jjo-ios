//
//  Glyph.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated struct Glyph: Equatable, Sendable, Identifiable {
    nonisolated enum Difference: String, Sendable {
        case replaced
        case added
        case skipped
    }

    var idx: Int
    var scalar: Unicode.Scalar
    var pitch = 0
    var stretch = 1.0
    var pace: UtteranceAnalysis.PaceLabel?
    var paceEnd = false
    var pauseMs = 0
    var diff: Difference?
    var segment = -1

    var id: Int { idx }
    var char: String { String(scalar) }
    var isEmphasized: Bool { pitch != 0 || stretch > 1 }
}
