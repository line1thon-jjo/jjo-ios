//
//  BrandDescription.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

struct BrandDescription: View {
    var body: some View {
        Text("대본을 읽는 내 목소리를\n글자 모양으로 확인해 보세요.")
            .font_15_medium(.textBody, lineHeight: .percent160)
            .padding(.top, -48)
    }
}

#Preview {
    BrandLayout {
        BrandDescription()
    }
}
