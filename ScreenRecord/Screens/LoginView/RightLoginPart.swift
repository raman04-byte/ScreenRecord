//
//  RightLoginPart.swift
//  ScreenRecord
//
//  Created by Raman Tank on 05/02/25.
//

import SwiftUI

struct RightLoginPart: View {
    var body: some View {
        ZStack(alignment: .bottomLeading){
            AsyncImage(url: URL(string: "https://stimg.cardekho.com/images/carexteriorimages/930x620/Porsche/911/11757/1717680690776/front-left-side-47.jpg")
            ){
                image in
                image.resizable()
                
            }placeholder: {
                ProgressView()
            }
            .frame(height: 500
                   ,alignment: .center
            )
            .aspectRatio(contentMode: .fit)
            .scaledToFit()
            VStack (alignment: .leading) {
                
                Text("Let's record your screen with ScreenRecord App and share it with your friends").foregroundColor(.white)
                    .font(
                        .largeTitle
                    )
            
                Button("Create account", action: {})
                    
            }.padding()
                
        }.cornerRadius(
            20
        )
    
    }
}

#Preview {
    RightLoginPart()
}
