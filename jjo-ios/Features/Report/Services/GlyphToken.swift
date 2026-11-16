//
//  GlyphToken.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated enum GlyphToken: Equatable, Sendable {
    case word([Glyph])
    case space(Glyph)
    case lineBreak(Glyph)
}
