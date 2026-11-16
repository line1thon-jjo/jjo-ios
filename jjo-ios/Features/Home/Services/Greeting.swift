//
//  Greeting.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated enum Greeting {
    static let closing = "오늘도 연습해 볼까요?"

    private static let slots: [(from: Int, text: String)] = [
        (5, "좋은 아침이에요"),
        (11, "좋은 오후예요"),
        (17, "좋은 저녁이에요"),
        (22, "늦은 시간까지 수고 많아요")
    ]

    static func text(hour: Int) -> String {
        slots.last { hour >= $0.from }?.text ?? slots[slots.count - 1].text
    }

    static func text(at date: Date = .now, calendar: Calendar = .current) -> String {
        text(hour: calendar.component(.hour, from: date))
    }
}
