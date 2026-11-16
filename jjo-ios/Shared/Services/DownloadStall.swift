//
//  DownloadStall.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import Foundation

nonisolated struct DownloadStall {
    let limit: Int
    private var fraction = -1.0
    private var idleTicks = 0

    init(limit: Int) {
        self.limit = limit
    }

    // 앱이 백그라운드에서 멈춰 있던 시간을 정체로 세지 않도록 시계 대신 확인 횟수로 센다
    mutating func isStalled(at next: Double) -> Bool {
        if next != fraction {
            fraction = next
            idleTicks = 0
            return false
        }
        idleTicks += 1
        return idleTicks >= limit
    }
}
