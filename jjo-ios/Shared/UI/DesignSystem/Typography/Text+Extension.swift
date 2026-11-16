//
//  Text+Extension.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import CoreText
import SwiftUI

nonisolated enum Pretendard: String, CaseIterable, Sendable {
    case bold = "Pretendard-Bold"
    case semiBold = "Pretendard-SemiBold"
    case medium = "Pretendard-Medium"
    case regular = "Pretendard-Regular"

    var fileName: String { rawValue }
}

nonisolated enum TextLineHeight: Sendable {
    case natural
    case percent130
    case percent150
    case percent160
    case points(CGFloat)

    func points(for size: CGFloat) -> CGFloat? {
        switch self {
        case .natural: nil
        case .percent130: size * 1.3
        case .percent150: size * 1.5
        case .percent160: size * 1.6
        case .points(let value): value
        }
    }
}

nonisolated enum Typography {
    static let letterSpacingRatio: CGFloat = -0.025

    static func kerning(for size: CGFloat) -> CGFloat {
        size * letterSpacingRatio
    }
}

extension View {
    func font_10_medium(_ color: Color? = nil, lineHeight: TextLineHeight = .natural) -> some View {
        pretendard(.medium, 10, color, lineHeight: lineHeight, tracking: false)
    }

    func font_13_regular(_ color: Color? = nil, lineHeight: TextLineHeight = .percent130) -> some View {
        pretendard(.regular, 13, color, lineHeight: lineHeight)
    }

    func font_13_medium(_ color: Color? = nil, lineHeight: TextLineHeight = .percent130) -> some View {
        pretendard(.medium, 13, color, lineHeight: lineHeight)
    }

    func font_14_regular(_ color: Color? = nil, lineHeight: TextLineHeight = .percent130) -> some View {
        pretendard(.regular, 14, color, lineHeight: lineHeight)
    }

    func font_14_medium(_ color: Color? = nil, lineHeight: TextLineHeight = .percent130) -> some View {
        pretendard(.medium, 14, color, lineHeight: lineHeight)
    }

    func font_14_semibold(_ color: Color? = nil, lineHeight: TextLineHeight = .percent130) -> some View {
        pretendard(.semiBold, 14, color, lineHeight: lineHeight)
    }

    func font_15_regular(_ color: Color? = nil, lineHeight: TextLineHeight = .percent130) -> some View {
        pretendard(.regular, 15, color, lineHeight: lineHeight)
    }

    func font_15_medium(_ color: Color? = nil, lineHeight: TextLineHeight = .percent130) -> some View {
        pretendard(.medium, 15, color, lineHeight: lineHeight)
    }

    func font_15_semibold(_ color: Color? = nil, lineHeight: TextLineHeight = .percent130) -> some View {
        pretendard(.semiBold, 15, color, lineHeight: lineHeight)
    }

    func font_16_regular(_ color: Color? = nil, lineHeight: TextLineHeight = .percent130) -> some View {
        pretendard(.regular, 16, color, lineHeight: lineHeight)
    }

    func font_16_medium(_ color: Color? = nil, lineHeight: TextLineHeight = .percent130) -> some View {
        pretendard(.medium, 16, color, lineHeight: lineHeight)
    }

    func font_16_semibold(_ color: Color? = nil, lineHeight: TextLineHeight = .percent130) -> some View {
        pretendard(.semiBold, 16, color, lineHeight: lineHeight)
    }

    func font_16_bold(_ color: Color? = nil, lineHeight: TextLineHeight = .percent130) -> some View {
        pretendard(.bold, 16, color, lineHeight: lineHeight)
    }

    func font_17_regular(_ color: Color? = nil, lineHeight: TextLineHeight = .percent130) -> some View {
        pretendard(.regular, 17, color, lineHeight: lineHeight)
    }

    func font_17_semibold(_ color: Color? = nil, lineHeight: TextLineHeight = .percent130) -> some View {
        pretendard(.semiBold, 17, color, lineHeight: lineHeight)
    }

    func font_17_bold(_ color: Color? = nil, lineHeight: TextLineHeight = .percent130) -> some View {
        pretendard(.bold, 17, color, lineHeight: lineHeight)
    }

    func font_18_semibold(_ color: Color? = nil, lineHeight: TextLineHeight = .percent130) -> some View {
        pretendard(.semiBold, 18, color, lineHeight: lineHeight)
    }

    func font_18_bold(_ color: Color? = nil, lineHeight: TextLineHeight = .percent130) -> some View {
        pretendard(.bold, 18, color, lineHeight: lineHeight)
    }

    func font_20_regular(_ color: Color? = nil, lineHeight: TextLineHeight = .percent130) -> some View {
        pretendard(.regular, 20, color, lineHeight: lineHeight)
    }

    func font_20_semibold(_ color: Color? = nil, lineHeight: TextLineHeight = .percent130) -> some View {
        pretendard(.semiBold, 20, color, lineHeight: lineHeight)
    }

    func font_20_bold(_ color: Color? = nil, lineHeight: TextLineHeight = .percent130) -> some View {
        pretendard(.bold, 20, color, lineHeight: lineHeight)
    }

    func font_22_regular(_ color: Color? = nil, lineHeight: TextLineHeight = .percent130) -> some View {
        pretendard(.regular, 22, color, lineHeight: lineHeight)
    }

    func font_22_bold(_ color: Color? = nil, lineHeight: TextLineHeight = .percent130) -> some View {
        pretendard(.bold, 22, color, lineHeight: lineHeight)
    }

    func font_26_regular(_ color: Color? = nil, lineHeight: TextLineHeight = .percent130) -> some View {
        pretendard(.regular, 26, color, lineHeight: lineHeight)
    }

    func font_26_bold(_ color: Color? = nil, lineHeight: TextLineHeight = .percent130) -> some View {
        pretendard(.bold, 26, color, lineHeight: lineHeight)
    }

    func font_32_bold(_ color: Color? = nil, lineHeight: TextLineHeight = .percent130) -> some View {
        pretendard(.bold, 32, color, lineHeight: lineHeight)
    }

    func pretendard(
        _ weight: Pretendard,
        _ size: CGFloat,
        _ color: Color? = nil,
        lineHeight: TextLineHeight = .percent130,
        tracking: Bool = true
    ) -> some View {
        modifier(PretendardStyle(weight: weight, size: size, color: color, lineHeight: lineHeight, tracking: tracking))
    }
}

private struct PretendardStyle: ViewModifier {
    let weight: Pretendard
    let size: CGFloat
    let color: Color?
    let lineHeight: TextLineHeight
    let tracking: Bool

    func body(content: Content) -> some View {
        let styled = content
            .font(.custom(weight.rawValue, fixedSize: size))
            .kerning(tracking ? Typography.kerning(for: size) : 0)
            .lineHeight(lineHeight.points(for: size).map { .exact(points: $0) })

        if let color {
            styled.foregroundStyle(color)
        } else {
            styled
        }
    }
}
