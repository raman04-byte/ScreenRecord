import AVFoundation
import CoreMedia
import CoreImage
import OSLog

@MainActor
class VideoWriter {
    private let logger = Logger()
    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var audioInput: AVAssetWriterInput?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    
    private var isRecording = false
    private var startTime: CMTime?
    private var frameCount: Int64 = 0
    
    private let outputURL: URL
    private let videoSize: CGSize
    
    // Smooth transition properties
    private var currentCropRect: CGRect?
    private var targetCropRect: CGRect?
    private let transitionFrames = 10 // Number of frames for smooth transition
    private var transitionProgress = 0
    
    // Store full frame size
    private var fullFrameSize: CGSize?
    
    init(outputURL: URL, videoSize: CGSize) {
        self.outputURL = outputURL
        self.videoSize = videoSize
    }
    
    func updateTargetCrop(_ rect: CGRect?) {
        targetCropRect = rect
        transitionProgress = 0
    }
    
    func startWriting() throws {
        // Remove existing file if present
        try? FileManager.default.removeItem(at: outputURL)
        
        // Create asset writer
        assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        
        guard let assetWriter = assetWriter else {
            throw VideoWriterError.failedToCreateWriter
        }
        
        // Configure video input
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: videoSize.width,
            AVVideoHeightKey: videoSize.height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 10_000_000,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
            ]
        ]
        
        videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        videoInput?.expectsMediaDataInRealTime = true
        
        // Create pixel buffer adaptor
        let sourcePixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: videoSize.width,
            kCVPixelBufferHeightKey as String: videoSize.height,
            kCVPixelBufferMetalCompatibilityKey as String: true
        ]
        
        pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoInput!,
            sourcePixelBufferAttributes: sourcePixelBufferAttributes
        )
        
        // Configure audio input
        let audioSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2,
            AVEncoderBitRateKey: 128000
        ]
        
        audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
        audioInput?.expectsMediaDataInRealTime = true
        
        // Add inputs to writer
        if let videoInput = videoInput, assetWriter.canAdd(videoInput) {
            assetWriter.add(videoInput)
        }
        
        if let audioInput = audioInput, assetWriter.canAdd(audioInput) {
            assetWriter.add(audioInput)
        }
        
        // Start writing session
        assetWriter.startWriting()
        assetWriter.startSession(atSourceTime: .zero)
        
        isRecording = true
        logger.log("Started writing video to \(self.outputURL)")
    }
    
    func appendVideoFrame(_ sampleBuffer: CMSampleBuffer, cropRect: CGRect?) async throws {
        guard isRecording,
              let videoInput = videoInput,
              let pixelBufferAdaptor = pixelBufferAdaptor,
              videoInput.isReadyForMoreMediaData else {
            return
        }
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            throw VideoWriterError.failedToGetImageBuffer
        }
        
        // Store full frame size on first frame
        if fullFrameSize == nil {
            fullFrameSize = CGSize(
                width: CVPixelBufferGetWidth(imageBuffer),
                height: CVPixelBufferGetHeight(imageBuffer)
            )
        }
        
        let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        if startTime == nil {
            startTime = presentationTime
        }
        
        let relativeTime = CMTimeSubtract(presentationTime, startTime ?? .zero)
        
        // Update target crop if changed
        if cropRect != targetCropRect {
            targetCropRect = cropRect
            transitionProgress = 0
        }
        
        // Calculate interpolated crop rect for smooth transition
        let effectiveCropRect = calculateSmoothCrop()
        
        // Process the frame with crop/zoom if needed
        let processedBuffer: CVPixelBuffer
        if let crop = effectiveCropRect {
            processedBuffer = try await applyCrop(to: imageBuffer, cropRect: crop)
        } else {
            processedBuffer = try await resizeToOutput(imageBuffer)
        }
        
        pixelBufferAdaptor.append(processedBuffer, withPresentationTime: relativeTime)
        frameCount += 1
    }
    
    func appendAudioBuffer(_ sampleBuffer: CMSampleBuffer) throws {
        guard isRecording,
              let audioInput = audioInput,
              audioInput.isReadyForMoreMediaData else {
            return
        }
        
        audioInput.append(sampleBuffer)
    }
    
    func finishWriting() async throws {
        guard isRecording else { return }
        
        isRecording = false
        
        videoInput?.markAsFinished()
        audioInput?.markAsFinished()
        
        await assetWriter?.finishWriting()
        
        if let error = assetWriter?.error {
            logger.error("Error finishing writing: \(error.localizedDescription)")
            throw error
        }
        
        logger.log("Finished writing video. Total frames: \(self.frameCount)")
    }
    
    private func calculateSmoothCrop() -> CGRect? {
        // If no target, return current
        guard let target = targetCropRect else {
            // Transition back to full frame
            if let current = currentCropRect, transitionProgress < transitionFrames {
                let progress = CGFloat(transitionProgress) / CGFloat(transitionFrames)
                transitionProgress += 1
                
                guard let fullSize = fullFrameSize else { return current }
                let fullRect = CGRect(origin: .zero, size: fullSize)
                
                currentCropRect = interpolateRect(from: current, to: fullRect, progress: progress)
                return currentCropRect
            }
            currentCropRect = nil
            return nil
        }
        
        // If no current, set it to target immediately
        if currentCropRect == nil {
            currentCropRect = target
            return target
        }
        
        // Smooth interpolation
        if transitionProgress < transitionFrames {
            let progress = CGFloat(transitionProgress) / CGFloat(transitionFrames)
            transitionProgress += 1
            
            currentCropRect = interpolateRect(from: currentCropRect!, to: target, progress: progress)
            return currentCropRect
        }
        
        currentCropRect = target
        return target
    }
    
    private func interpolateRect(from start: CGRect, to end: CGRect, progress: CGFloat) -> CGRect {
        // Ease-in-out interpolation for smoother animation
        let t = easeInOutQuad(progress)
        
        return CGRect(
            x: start.origin.x + (end.origin.x - start.origin.x) * t,
            y: start.origin.y + (end.origin.y - start.origin.y) * t,
            width: start.width + (end.width - start.width) * t,
            height: start.height + (end.height - start.height) * t
        )
    }
    
    private func easeInOutQuad(_ t: CGFloat) -> CGFloat {
        if t < 0.5 {
            return 2 * t * t
        } else {
            return -1 + (4 - 2 * t) * t
        }
    }
    
    private func resizeToOutput(_ pixelBuffer: CVPixelBuffer) async throws -> CVPixelBuffer {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        let sourceWidth = CVPixelBufferGetWidth(pixelBuffer)
        let sourceHeight = CVPixelBufferGetHeight(pixelBuffer)
        
        let scaleX = videoSize.width / CGFloat(sourceWidth)
        let scaleY = videoSize.height / CGFloat(sourceHeight)
        
        let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        let context = CIContext()
        guard let outputBuffer = try createPixelBuffer() else {
            throw VideoWriterError.failedToCreatePixelBuffer
        }
        
        context.render(scaledImage, to: outputBuffer)
        return outputBuffer
    }
    
    private func applyCrop(to pixelBuffer: CVPixelBuffer, cropRect: CGRect) async throws -> CVPixelBuffer {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        let sourceWidth = CVPixelBufferGetWidth(pixelBuffer)
        let sourceHeight = CVPixelBufferGetHeight(pixelBuffer)
        
        // Clamp crop rect to valid bounds
        let clampedRect = CGRect(
            x: max(0, min(cropRect.origin.x, CGFloat(sourceWidth - 1))),
            y: max(0, min(cropRect.origin.y, CGFloat(sourceHeight - 1))),
            width: min(cropRect.width, CGFloat(sourceWidth) - cropRect.origin.x),
            height: min(cropRect.height, CGFloat(sourceHeight) - cropRect.origin.y)
        )
        
        // Crop the image (Core Image uses bottom-left origin, so flip Y)
        let flippedY = CGFloat(sourceHeight) - clampedRect.origin.y - clampedRect.height
        let flippedCropRect = CGRect(
            x: clampedRect.origin.x,
            y: flippedY,
            width: clampedRect.width,
            height: clampedRect.height
        )
        
        let croppedImage = ciImage.cropped(to: flippedCropRect)
        
        // Scale to output size
        let scaleX = videoSize.width / clampedRect.width
        let scaleY = videoSize.height / clampedRect.height
        
        let scaledImage = croppedImage
            .transformed(by: CGAffineTransform(translationX: -flippedCropRect.origin.x, y: -flippedCropRect.origin.y))
            .transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        // Render to pixel buffer
        let context = CIContext()
        guard let outputBuffer = try createPixelBuffer() else {
            throw VideoWriterError.failedToCreatePixelBuffer
        }
        
        context.render(scaledImage, to: outputBuffer)
        return outputBuffer
    }
    
    private func createPixelBuffer() throws -> CVPixelBuffer? {
        if let pool = pixelBufferAdaptor?.pixelBufferPool {
            var buffer: CVPixelBuffer?
            let status = CVPixelBufferPoolCreatePixelBuffer(nil, pool, &buffer)
            if status != kCVReturnSuccess {
                throw VideoWriterError.failedToCreatePixelBuffer
            }
            return buffer
        }
        return nil
    }
}

enum VideoWriterError: Error {
    case failedToCreateWriter
    case failedToGetImageBuffer
    case failedToCreatePixelBuffer
}