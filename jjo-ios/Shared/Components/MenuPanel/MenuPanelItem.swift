//
//  MenuPanelItem.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

struct MenuPanelItem: Identifiable {
    enum Role {
        case normal
        case destructive
    }

    enum Accessory {
        case none
        case chevron
        case toggle(isOn: Bool)
    }

    let id: String
    let title: String
    var role: Role = .normal
    var accessory: Accessory = .chevron
    let action: () -> Void

    init(
        id: String? = nil,
        title: String,
        role: Role = .normal,
        accessory: Accessory = .chevron,
        action: @escaping () -> Void
    ) {
        self.id = id ?? title
        self.title = title
        self.role = role
        self.accessory = accessory
        self.action = action
    }
}
