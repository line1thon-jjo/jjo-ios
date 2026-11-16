//
//  ScriptSampleTests.swift
//  jjo-ios-Tests
//
//  Created by dohyeoplim on 11/16/26.
//

import Testing
@testable import jjo_ios

struct ScriptSampleTests {
    @Test func passesValidation() {
        #expect(ScriptValidator.error(in: ScriptSample.text) == nil)
    }
}
