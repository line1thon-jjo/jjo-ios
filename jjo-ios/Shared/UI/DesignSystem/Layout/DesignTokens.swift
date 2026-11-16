//
//  DesignTokens.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import CoreGraphics

nonisolated enum Spacing {
    static let x1: CGFloat = 4
    static let x2: CGFloat = 8
    static let x3: CGFloat = 12
    static let x4: CGFloat = 16
    static let x5: CGFloat = 20
    static let x6: CGFloat = 24
    static let x8: CGFloat = 32
    static let x10: CGFloat = 40

    static let screenHorizontal: CGFloat = 20
    // 웹의 --bottom-action-gap 54px는 화면 맨 아래 기준이라 홈 인디케이터 34pt를 뺀 값을 쓴다
    static let bottomAction: CGFloat = 20
    static let bottomActionFromEdge: CGFloat = 54
}

nonisolated enum Radius {
    static let none: CGFloat = 0
    static let handle: CGFloat = 2
    static let indicator: CGFloat = 3
    static let skeleton: CGFloat = 6
    static let notice: CGFloat = 8
    static let toggle: CGFloat = 13
    static let sheet: CGFloat = 20
    static let pill: CGFloat = 999
}

nonisolated enum IconSize {
    static let tiny: CGFloat = 12
    static let small: CGFloat = 16
    static let medium: CGFloat = 20
    static let large: CGFloat = 32
}

nonisolated enum Layout {
    static let headerHeight: CGFloat = 64
    static let headerLogoHeight: CGFloat = 32
    static let headerButton: CGFloat = 32
    static let touchTarget: CGFloat = 44
    static let greenButtonHeight: CGFloat = 53
    static let pillButtonHeight: CGFloat = 50
    static let floatingButton: CGFloat = 56
    static let avatar: CGFloat = 52
    static let sheetMaxHeightRatio: CGFloat = 0.8
    static let sheetHandleWidth: CGFloat = 36
    static let sheetHandleHeight: CGFloat = 4
}
