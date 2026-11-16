//
//  BrandAccent.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

struct BrandAccent: Shape {
    var leading: CGFloat
    var slant: CGFloat = 14

    nonisolated var animatableData: CGFloat {
        get { leading }
        set { leading = newValue }
    }

    nonisolated func path(in rect: CGRect) -> Path {
        var path = Path()
        guard leading < rect.maxX else { return path }

        path.move(to: CGPoint(x: min(leading + slant, rect.maxX), y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: leading, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    BrandAccent(leading: 80)
        .fill(Color.lime)
        .frame(height: 23)
        .padding(.leading, Spacing.screenHorizontal)
}
