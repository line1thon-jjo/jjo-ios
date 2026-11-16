//
//  NavigationManager+Instant.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

extension NavigationManager {
    func instantly(_ change: (NavigationManager) -> Void) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { change(self) }
    }
}
