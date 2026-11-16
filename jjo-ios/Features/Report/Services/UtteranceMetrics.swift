//
//  UtteranceMetrics.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import CoreGraphics

nonisolated enum UtteranceMetrics {
    static let fontSize: CGFloat = 21
    static let lineHeight: CGFloat = fontSize * 2.15
    static let tracking: CGFloat = fontSize * -0.025
    static let fastSpacing: CGFloat = fontSize * -0.07
    static let slowSpacing: CGFloat = fontSize * 0.09
    static let stretchMargin: CGFloat = fontSize * 0.9
    static let pitchStep: CGFloat = fontSize * 0.16
    static let pauseMinWidth: CGFloat = fontSize * 2.2
    static let pauseWidthPerSecond: CGFloat = fontSize * 2
    static let pauseMaxSeconds = 2.0
    static let ascent: CGFloat = fontSize * 1950 / 2048
    static let descent: CGFloat = fontSize * 494 / 2048
    static let contentTop: CGFloat = (lineHeight - ascent - descent) / 2
    static let baseline: CGFloat = contentTop + ascent
    static let highlightHeight: CGFloat = ascent + descent + fontSize * 0.2
    static let underlineTop: CGFloat = contentTop + fontSize * 1.16 + 1
    static let pauseTop: CGFloat = baseline - fontSize * 0.268 - fontSize / 2
    static let focusDimOpacity = 0.22
    static let skippedOpacity = 0.4

    static func visualStretch(_ ratio: Double) -> CGFloat {
        ratio <= 1 ? 1 : CGFloat(min(2, 1 + (ratio - 1) * 0.33))
    }

    static func pauseWidth(_ durationMs: Int) -> CGFloat {
        guard durationMs > 0 else { return 0 }
        return max(pauseMinWidth, CGFloat(min(Double(durationMs) / 1000, pauseMaxSeconds)) * pauseWidthPerSecond)
    }

    static func paceSpacing(_ pace: UtteranceAnalysis.PaceLabel?) -> CGFloat {
        switch pace {
        case .fast: fastSpacing
        case .slow: slowSpacing
        case nil: 0
        }
    }
}
