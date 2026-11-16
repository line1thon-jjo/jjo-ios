//
//  Route.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

enum Route: Hashable {
    case script
    case record(practiceID: UUID)
    case report(practiceID: UUID, recordingID: UUID)
}
