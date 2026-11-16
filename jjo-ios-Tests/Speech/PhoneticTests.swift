//
//  PhoneticTests.swift
//  jjo-ios-Tests
//
//  Created by dohyeoplim on 11/16/26.
//

import Testing
@testable import jjo_ios

struct PhoneticTests {
    @Test func contractionsMatch() {
        let pairs = [("되어서야", "돼서야"), ("것인지는", "건지는"), ("보여 주는", "보여준"), ("그것은", "그건"), ("하여", "해")]
        for (full, short) in pairs {
            #expect(Phonetic.soundDistance(full, short) == 0)
        }
        #expect(Phonetic.soundDistance("사례", "살해") > 0.3)
    }

    @Test func measuresDistance() {
        #expect(Phonetic.soundDistance("사례", "살해") <= 0.5)
        #expect(Phonetic.soundDistance("앓은", "알은") <= 0.5)
        #expect(Phonetic.soundDistance("결제", "계약") > 0.5)
        #expect(Phonetic.soundDistance("결제", "결제") == 0)
        #expect(Phonetic.soundDistance("", "") == 0)
        #expect(Phonetic.soundDistance("결제", "결재") == 0)
    }
}
