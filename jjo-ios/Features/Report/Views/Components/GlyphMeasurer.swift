//
//  GlyphMeasurer.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import UIKit

final class GlyphMeasurer {
    static let shared = GlyphMeasurer()

    private let regular = GlyphMeasurer.font(.regular)
    private let heavy = GlyphMeasurer.font(.bold)
    private var cache: [Unicode.Scalar: GlyphWidth] = [:]

    func width(of scalar: Unicode.Scalar) -> GlyphWidth {
        if let cached = cache[scalar] { return cached }
        let text = String(scalar) as NSString
        let measured = GlyphWidth(
            regular: text.size(withAttributes: [.font: regular]).width,
            heavy: text.size(withAttributes: [.font: heavy]).width
        )
        cache[scalar] = measured
        return measured
    }

    private static func font(_ weight: Pretendard) -> UIFont {
        UIFont(name: weight.rawValue, size: UtteranceMetrics.fontSize)
            ?? .systemFont(ofSize: UtteranceMetrics.fontSize, weight: weight == .bold ? .bold : .regular)
    }
}
