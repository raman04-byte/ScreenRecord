//
//  CaptureMouse.swift
//  ScreenRecord
//
//  Created by Raman Tank on 03/02/25.
//
import SwiftUI
import AppKit

class GlobalMouseTracker: ObservableObject {
    @Published var mouseLocation: NSPoint = .zero
    private var globalMonitor: Any?
    
    init() {
        // Set up the global monitor for mouse moved events.
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            // NSEvent.mouseLocation gives the current global mouse coordinates.
            let currentLocation = NSEvent.mouseLocation
            // Update on the main thread.
            DispatchQueue.main.async {
                self?.mouseLocation = currentLocation
                print("Global mouse moved to: \(currentLocation)")
            }
        }
    }
    
    deinit {
        // Remove the global event monitor when this object is deallocated.
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
