//
//  ContentView.swift
//  ScreenRecord
//
//  Created by Raman Tank on 01/02/25.
//

import SwiftUI
import AppKit

struct ContentView: View {
    @State var userStopped = false
    @State var disableInput = false
    @State var isUnauthorized = false

    @StateObject var screenRecorder = ScreenRecorder()
    @StateObject var mouseTracker = GlobalMouseTracker()
    
    // This state will track whether Command is pressed.
    @State private var isCommandPressed = false
    
    var body: some View {
        HSplitView {
            ConfigurationView(screenRecorder: screenRecorder, userStopped: $userStopped)
                .frame(minWidth: 280, maxWidth: 280)
                .disabled(disableInput)
            screenRecorder.capturePreview
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aspectRatio(screenRecorder.contentSize, contentMode: .fit)
                .padding(8)
                .overlay {
                    if userStopped {
                        Image(systemName: "nosign")
                            .font(.system(size: 250, weight: .bold))
                            .foregroundColor(Color(white: 0.3, opacity: 1.0))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(white: 0.0, opacity: 0.5))
                    }
                }
        }
        .overlay {
            if isUnauthorized {
                VStack {
                    Spacer()
                    VStack {
                        Text("No screen recording permission.")
                            .font(.largeTitle)
                            .padding(.top)
                        Text("Open System Settings and go to Privacy & Security > Screen Recording to grant permission.")
                            .font(.title2)
                            .padding(.bottom)
                    }
                    .frame(maxWidth: .infinity)
                    .background(.red)
                }
            }
        }
        .navigationTitle("Record Screen")
        .onAppear {
            Task {
                if await screenRecorder.canRecord {
                    await screenRecorder.start()
                } else {
                    isUnauthorized = true
                    disableInput = true
                }
            }
            // Monitor Command key changes.
            NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { event in
                let commandDown = event.modifierFlags.contains(.shift)
                if commandDown != isCommandPressed {
                    isCommandPressed = commandDown
                    if commandDown {
                        // When Command is pressed, update the crop region using the current mouse location.
                        let mouseLocation = NSEvent.mouseLocation
                        let cropRect = CGRect(x: mouseLocation.x - 150, y: mouseLocation.y - 150, width: 300, height: 300)
                        Task {
                            await screenRecorder.updateCropRect(cropRect)
                        }
                    } else {
                        // When Command is released, reset to full screen.
                        Task {
                            await screenRecorder.updateCropRect(nil)
                        }
                    }
                }
                return event
            }
        }
        // Update the crop region continuously as the mouse moves, but only when Command is pressed.
        .onChange(of: mouseTracker.mouseLocation) { newLocation in
            if isCommandPressed {
                let cropRect = CGRect(x: newLocation.x - 150, y: newLocation.y - 150, width: 300, height: 300)
                Task {
                    await screenRecorder.updateCropRect(cropRect)
                }
            }
        }
    }
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
