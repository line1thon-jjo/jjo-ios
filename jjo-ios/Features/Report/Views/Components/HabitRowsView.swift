//
//  HabitRowsView.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

struct HabitRowsView: View {
    let rows: [HabitRow]
    var onFocusPace: ((UtteranceAnalysis.PaceLabel) -> Void)?

    var body: some View {
        if rows.isEmpty {
            Text("빠르거나 느린 구절, 반복된 습관이 없었어요.")
                .font_15_regular(.textBody)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            VStack(spacing: 0) {
                ForEach(rows) { row in
                    rowView(row)
                        .padding(.bottom, 1)
                        .overlay(alignment: .bottom) {
                            Rectangle()
                                .fill(Color.line)
                                .frame(height: 1)
                        }
                }
            }
        }
    }

    @ViewBuilder
    private func rowView(_ row: HabitRow) -> some View {
        if let onFocusPace, let pace = row.pace, !row.isCleared {
            Button {
                Haptics.select()
                onFocusPace(pace)
            } label: {
                content(row, showsChevron: true)
            }
            .buttonStyle(.pressable)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(row.label) \(row.after)\(row.unit), 상세 분석에서 위치 보기")
            .accessibilityValue(row.difference.map { ReportCopy.trend($0, unit: row.unit) } ?? "")
        } else {
            content(row, showsChevron: false)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(row.label) \(row.after)\(row.unit)")
                .accessibilityValue(row.difference.map { ReportCopy.trend($0, unit: row.unit) } ?? "")
        }
    }

    private func content(_ row: HabitRow, showsChevron: Bool) -> some View {
        HStack(spacing: Spacing.x4) {
            Text(row.label)
                .font_16_medium(row.isCleared ? .textFaint : .ink)

            Spacer(minLength: 0)

            HStack(spacing: 10) {
                Text("\(row.after)\(row.unit)")
                    .font_16_semibold(row.isCleared ? .textFaint : .ink)
                if let difference = row.difference {
                    trend(difference)
                }
                if showsChevron {
                    Icon(.iconChevronRight, size: IconSize.small, color: .textIcon)
                        .padding(.trailing, -Spacing.x1)
                }
            }
            .padding(.trailing, showsChevron ? 0 : Spacing.x3)
        }
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }

    private func trend(_ difference: Int) -> some View {
        let color: Color = if difference == 0 { .textFaint } else if difference < 0 { .olive } else { .paceFast }

        return HStack(spacing: 2) {
            if difference != 0 {
                TrendArrow()
                    .stroke(color, style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
                    .frame(width: 9, height: 11)
                    .rotationEffect(.degrees(difference < 0 ? 180 : 0))
            }
            Text(difference == 0 ? "–" : "\(abs(difference))")
                .font_14_semibold(color)
        }
        .frame(minWidth: 28, alignment: .trailing)
    }
}

private struct TrendArrow: Shape {
    nonisolated func path(in rect: CGRect) -> Path {
        let unitX = rect.width / 10
        let unitY = rect.height / 12
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * unitX, y: rect.minY + y * unitY)
        }

        var path = Path()
        path.move(to: point(5, 11))
        path.addLine(to: point(5, 1))
        path.move(to: point(1, 5))
        path.addLine(to: point(5, 1))
        path.addLine(to: point(9, 5))
        return path
    }
}

#Preview {
    HabitRowsView(
        rows: [
            HabitRow(id: "fast", label: "빠른 구절", unit: "곳", pace: .fast, after: 3, before: 5),
            HabitRow(id: "MID_STRETCH", label: "중간 늘임", unit: "회", after: 3, before: 3),
            HabitRow(id: "slow", label: "느린 구절", unit: "곳", pace: .slow, after: 2, before: 1),
            HabitRow(id: "END_RISE", label: "끝 올림", unit: "회", after: 0, before: 4)
        ],
        onFocusPace: { _ in }
    )
    .padding(Spacing.screenHorizontal)
    .background(Color.background)
}
