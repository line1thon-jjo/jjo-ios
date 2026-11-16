//
//  Haptics.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import UIKit

@MainActor
enum Haptics {
    private static let selection = UISelectionFeedbackGenerator()
    private static let light = UIImpactFeedbackGenerator(style: .light)
    private static let medium = UIImpactFeedbackGenerator(style: .medium)
    private static let soft = UIImpactFeedbackGenerator(style: .soft)
    private static let rigid = UIImpactFeedbackGenerator(style: .rigid)
    private static let notification = UINotificationFeedbackGenerator()

    static func prepare() {
        selection.prepare()
        light.prepare()
        medium.prepare()
        soft.prepare()
        rigid.prepare()
    }

    static func press() {
        light.impactOccurred(intensity: 0.55)
    }

    static func select() {
        selection.selectionChanged()
    }

    static func open() {
        medium.impactOccurred(intensity: 0.8)
    }

    static func close() {
        soft.impactOccurred(intensity: 0.5)
    }

    static func commit() {
        rigid.impactOccurred(intensity: 1.0)
    }

    static func success() {
        notification.notificationOccurred(.success)
    }

    static func warning() {
        notification.notificationOccurred(.warning)
    }

    static func error() {
        notification.notificationOccurred(.error)
    }
}
