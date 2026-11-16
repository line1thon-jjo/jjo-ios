//
//  HeaderLogo.swift
//  jjo-ios
//
//  Created by dohyeoplim on 11/16/26.
//

import SwiftUI

struct HeaderLogo: View {
    var body: some View {
        Image(.logoJjo)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: Layout.headerLogoHeight)
            .accessibilityLabel("jjo")
    }
}

#Preview {
    HeaderLogo()
        .padding(Spacing.screenHorizontal)
        .background(Color.background)
}
