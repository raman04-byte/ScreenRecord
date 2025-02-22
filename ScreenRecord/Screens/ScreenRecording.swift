//
//  ScreenRecording.swift
//  ScreenRecord
//
//  Created by Raman Tank on 05/02/25.
//

import SwiftUI

struct ScreenRecording: View {
    @State var userStopped = false
    @State var disableInput = false
    @State var isUnauthorized = false

    @StateObject var screenRecorder = ScreenRecorder()
    @StateObject var mouseTracker = GlobalMouseTracker()
    
    // This state will track whether Command is pressed.
    @State private var isShiftDown = false
    
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
            NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { event in
                let shiftDown = event.modifierFlags.contains(.shift)
                if shiftDown != isShiftDown {
                    isShiftDown = shiftDown
                    if shiftDown {
                        let mouseLocation = NSEvent.mouseLocation
                        let cropRect = CGRect(x: mouseLocation.x - 150, y: mouseLocation.y - 150, width: 300, height: 300)
                        Task {
                            await screenRecorder.updateCropRect(cropRect)
                        }
                    } else {
                        Task {
                            await screenRecorder.updateCropRect(nil)
                        }
                    }
                }
                
            }
        }
        .onChange(of: mouseTracker.mouseLocation) {
            if isShiftDown {
                let cropRect = CGRect(
                    x: mouseTracker.mouseLocation.x - 150,
                    y: mouseTracker.mouseLocation.y - 150,
                    width: 300,
                    height: 300
                )
                Task {
                    await screenRecorder.updateCropRect(cropRect)
                }
            }
        }

    }
}

#Preview {
    ScreenRecording()
}
