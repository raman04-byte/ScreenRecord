//
//  Login.swift
//  ScreenRecord
//
//  Created by Raman Tank on 05/02/25.
//

import SwiftUI

struct Login: View {
    var body: some View {
        HStack(
            alignment: .center,
            spacing: 20){
                LeftLoginPart()
                RightLoginPart()
            }
            .padding()
    }
}
#Preview {
    Login()
}
