//
//  GlyphWidth.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import CoreGraphics

nonisolated struct GlyphWidth: Equatable, Sendable {
    var regular: CGFloat
    var heavy: CGFloat

    var box: CGFloat { max(regular, heavy) }
}
