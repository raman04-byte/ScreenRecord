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
    
    func updateFrame(_ frame: CapturedFrame, cropRect: CGRect? = nil) {
        // Disable or reduce animations:
        CATransaction.begin()
//        CATransaction.setDisableActions(true)
        CATransaction.setAnimationDuration(0.25)
        
        if let crop = cropRect {
            let fullSize = frame.size
            let normalizedRect = CGRect(
                x: crop.origin.x / fullSize.width,
                y: crop.origin.y / fullSize.height,
                width: crop.size.width / fullSize.width,
                height: crop.size.height / fullSize.height
            )
            contentLayer.contentsRect = normalizedRect
        } else {
            contentLayer.contentsRect = CGRect(x: 0, y: 0, width: 1, height: 1)
        }
        
        // Update the layer’s contents with the IOSurface.
        contentLayer.contents = frame.surface
        
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
