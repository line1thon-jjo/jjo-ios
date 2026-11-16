//
//  NavigationManager.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

@Observable
final class NavigationManager {
    var path: [Route] = []

    func push(_ route: Route) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path.removeAll()
    }

    func replaceTop(with route: Route) {
        guard !path.isEmpty else {
            path = [route]
            return
        }
        path[path.count - 1] = route
    }
}
