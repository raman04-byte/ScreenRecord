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
                        updateCropForCurrentMouse()
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
                updateCropForCurrentMouse()
            }
        }
    }
    
    private func updateCropForCurrentMouse() {
    guard let mainScreen = NSScreen.main else { return }
    
    let mouseLocation = mouseTracker.mouseLocation
    let scaleFactor = mainScreen.backingScaleFactor
    
    let screenHeight = mainScreen.frame.height
    
    // Flip Y coordinate to convert from bottom-left to top-left origin
    let flippedMouseY = screenHeight - mouseLocation.y
    
    // Scale the crop size and position for retina displays
    let cropSize: CGFloat = 500 * scaleFactor
    let halfSize = cropSize / 2
    
    // Scale mouse coordinates to match the backing store resolution
    let scaledMouseX = mouseLocation.x * scaleFactor
    let scaledMouseY = flippedMouseY * scaleFactor
    
    let cropRect = CGRect(
        x: scaledMouseX - halfSize,
        y: scaledMouseY - halfSize,
        width: cropSize,
        height: cropSize
    )
    
    Task {
        await screenRecorder.updateCropRect(cropRect)
    }
}
}

#Preview {
    ScreenRecording()
}
