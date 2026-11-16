//
//  DownloadStallTests.swift
//  jjo-ios-Tests
//
//  Created by dohyeoplim on 11/16/26.
//

import Testing
@testable import jjo_ios

struct DownloadStallTests {
    @Test
    func stallsWhenIdle() {
        var stall = DownloadStall(limit: 3)
        let checks = [0.2, 0.2, 0.2, 0.2].map { stall.isStalled(at: $0) }
        #expect(checks == [false, false, false, true])
    }

    @Test
    func resetsOnProgress() {
        var stall = DownloadStall(limit: 2)
        let checks = [0.0, 0.0, 0.1, 0.1, 0.2, 0.2].map { stall.isStalled(at: $0) }
        #expect(checks.allSatisfy { !$0 })
    }
}
