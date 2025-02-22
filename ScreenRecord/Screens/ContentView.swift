//
//  ContentView.swift
//  ScreenRecord
//
//  Created by Raman Tank on 01/02/25.
//

import SwiftUI
import AppKit

struct ContentView: View {
    @State private var showLoginScreen = false
    var body: some View {
        Group{
            if showLoginScreen {
                ScreenRecording()
            } else {
                VStack {
                    ProgressView("Loading...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        showLoginScreen = true
                    }
                }
            }
        }
        .frame(
            maxWidth: .infinity
            ,
            maxHeight: .infinity
        )
    }
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
