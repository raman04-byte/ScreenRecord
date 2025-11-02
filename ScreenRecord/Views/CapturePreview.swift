import SwiftUI

struct CapturePreview: NSViewRepresentable {
    
    // A layer that renders the video contents.
    private let contentLayer = CALayer()
    
    init() {
        contentLayer.contentsGravity = .resizeAspect
        // Optionally, set a default animation for property changes.
        // (You can also use explicit CATransaction blocks in updateFrame.)
        contentLayer.actions = ["contentsRect": CABasicAnimation()]
    }
    
    func makeNSView(context: Context) -> CaptureVideoPreview {
        CaptureVideoPreview(layer: contentLayer)
    }
    
    func updateFrame(_ frame: CapturedFrame) {
        // Just update the surface, don't touch contentsRect here
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        // Update the layer's contents with the IOSurface.
        contentLayer.contents = frame.surface
        
        CATransaction.commit()
    }
    
    func updateContentRect(_ rect: CGRect?) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.25)
        
        if let rect = rect {
            // Get the current frame dimensions (in pixels)
            guard let surface = contentLayer.contents as? IOSurface else {
                CATransaction.commit()
                return
            }
            
            let surfaceWidth = CGFloat(IOSurfaceGetWidth(surface))
            let surfaceHeight = CGFloat(IOSurfaceGetHeight(surface))
            
            // IMPORTANT: CALayer uses bottom-left origin, so we need to flip Y
            // Screen capture rect has top-left origin, CALayer needs bottom-left
            let flippedY = surfaceHeight - rect.origin.y - rect.height
            
            // Convert pixel coordinates to normalized coordinates (0.0 to 1.0)
            let normalizedRect = CGRect(
                x: rect.origin.x / surfaceWidth,
                y: flippedY / surfaceHeight,  // Use flipped Y
                width: rect.size.width / surfaceWidth,
                height: rect.size.height / surfaceHeight
            )
            
            // Clamp to valid range [0, 1]
            let clampedRect = CGRect(
                x: max(0, min(normalizedRect.origin.x, 1.0)),
                y: max(0, min(normalizedRect.origin.y, 1.0)),
                width: max(0, min(normalizedRect.size.width, 1.0 - normalizedRect.origin.x)),
                height: max(0, min(normalizedRect.size.height, 1.0 - normalizedRect.origin.y))
            )
            
            contentLayer.contentsRect = clampedRect
        } else {
            // Reset to full frame
            contentLayer.contentsRect = CGRect(x: 0, y: 0, width: 1, height: 1)
        }
        
        CATransaction.commit()
    }

    
    // The view itself is not updated by SwiftUI.
    func updateNSView(_ nsView: CaptureVideoPreview, context: Context) {}
    
    class CaptureVideoPreview: NSView {
        init(layer: CALayer) {
            super.init(frame: .zero)
            self.layer = layer
            wantsLayer = true
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
