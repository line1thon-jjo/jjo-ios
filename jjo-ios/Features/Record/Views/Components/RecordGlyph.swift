//
//  RecordGlyph.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

enum RecordGlyph {
    case pause
    case play
    case stop
    case check
}

extension RecordGlyph: View {
    var body: some View {
        switch self {
        case .pause:
            HStack(spacing: 3) {
                RoundedRectangle(cornerRadius: 1).frame(width: 3.5, height: 12)
                RoundedRectangle(cornerRadius: 1).frame(width: 3.5, height: 12)
            }
            .foregroundStyle(Color.pureWhite)
            .frame(width: IconSize.small, height: IconSize.small)
        case .play:
            PlayTriangle()
                .fill(Color.pureWhite)
                .frame(width: IconSize.small, height: IconSize.small)
        case .stop:
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.recordRed)
                .frame(width: 14, height: 14)
        case .check:
            CheckMark()
                .stroke(Color.pureBlack, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                .frame(width: 24, height: 24)
        }
    }
}

private struct PlayTriangle: Shape {
    nonisolated func path(in rect: CGRect) -> Path {
        let unit = rect.width / 16
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + 4 * unit, y: rect.minY + 2.5 * unit))
        path.addLine(to: CGPoint(x: rect.minX + 4 * unit, y: rect.minY + 13.5 * unit))
        path.addLine(to: CGPoint(x: rect.minX + 13 * unit, y: rect.minY + 8 * unit))
        path.closeSubpath()
        return path
    }
}

private struct CheckMark: Shape {
    nonisolated func path(in rect: CGRect) -> Path {
        let unit = rect.width / 24
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + 5 * unit, y: rect.minY + 12.5 * unit))
        path.addLine(to: CGPoint(x: rect.minX + 10 * unit, y: rect.minY + 17.5 * unit))
        path.addLine(to: CGPoint(x: rect.minX + 19 * unit, y: rect.minY + 7 * unit))
        return path
    }
}
