import UIKit
@preconcurrency import Vision
import CoreGraphics

/// Adapter that wraps Vision framework contour detection to conform to LineArtExtractorProtocol
/// Returns EdgeMap (binary) instead of processed UIImage
final class VisionExtractorAdapter: LineArtExtractorProtocol {
    var engineName: String { "VisionContours" }
    var isAvailable: Bool { true }  // Available on iOS 14+
    var preferredInputSize: Int { 512 }  // Default, can be overridden by settings

    func extractEdges(
        from preprocessedImage: CGImage,
        settings: LineArtSettings
    ) async throws -> EdgeMap {
        let startTime = CFAbsoluteTimeGetCurrent()

        // Detect polarity
        let isDarkOnLight = detectPolarity(preprocessedImage)

        // Configure contour detection
        let request = VNDetectContoursRequest()
        request.contrastAdjustment = settings.contrastAdjustment
        request.detectsDarkOnLight = isDarkOnLight
        request.maximumImageDimension = settings.maxDimension

        // Run detection
        let handler = VNImageRequestHandler(cgImage: preprocessedImage, options: [:])

        let contourImage: CGImage = try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])

                    guard let observation = request.results?.first else {
                        continuation.resume(throwing: ProcessingError.extractionFailed("No contours detected"))
                        return
                    }

                    let size = CGSize(width: preprocessedImage.width, height: preprocessedImage.height)
                    let rendered = self.renderContours(observation, size: size)

                    guard let cgImage = rendered.cgImage else {
                        continuation.resume(throwing: ProcessingError.extractionFailed("Failed to render contours"))
                        return
                    }

                    continuation.resume(returning: cgImage)
                } catch {
                    continuation.resume(throwing: ProcessingError.extractionFailed(error.localizedDescription))
                }
            }
        }

        let processingTime = Int((CFAbsoluteTimeGetCurrent() - startTime) * 1000)

        // Compute edge density
        let edgeDensity = EdgeMap.computeEdgeDensity(from: contourImage, isBinary: true)

        let meta = EngineMeta(
            engineName: engineName,
            suggestedThreshold: 0.5,  // Already binary
            edgeDensity: edgeDensity,
            processingTimeMs: processingTime,
            originalScale: CGFloat(preprocessedImage.width) / CGFloat(settings.maxDimension)
        )

        return EdgeMap(
            data: contourImage,
            isBinary: true,  // Vision contours render as binary
            engineMeta: meta
        )
    }

    // MARK: - Private Methods

    private func detectPolarity(_ image: CGImage) -> Bool {
        // Sample center pixels to determine if content is dark on light or light on dark
        let width = image.width
        let height = image.height

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return true }

        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let data = context.data else { return true }
        let pixels = data.bindMemory(to: UInt8.self, capacity: width * height)

        // Sample 100 pixels from center region
        var totalBrightness = 0
        let sampleCount = 100
        let centerX = width / 2
        let centerY = height / 2
        let sampleRadius = min(width, height) / 4

        for i in 0..<sampleCount {
            let angle = Double(i) * 2.0 * .pi / Double(sampleCount)
            let x = centerX + Int(Double(sampleRadius) * cos(angle) * 0.8)
            let y = centerY + Int(Double(sampleRadius) * sin(angle) * 0.8)

            if x >= 0 && x < width && y >= 0 && y < height {
                totalBrightness += Int(pixels[y * width + x])
            }
        }

        let avgBrightness = totalBrightness / sampleCount

        // If average brightness > 128, background is light (dark on light)
        return avgBrightness > 128
    }

    private func renderContours(_ observation: VNContoursObservation, size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            // White background
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))

            // Black lines
            UIColor.black.setStroke()
            ctx.cgContext.setLineWidth(1.5)

            // Transform from normalized coordinates to image coordinates
            let transform = CGAffineTransform(scaleX: size.width, y: size.height)
                .concatenating(CGAffineTransform(scaleX: 1, y: -1))
                .concatenating(CGAffineTransform(translationX: 0, y: size.height))

            for contourIndex in 0..<observation.contourCount {
                if let contour = try? observation.contour(at: contourIndex) {
                    let path = contour.normalizedPath.copy(using: [transform])
                    if let cgPath = path {
                        ctx.cgContext.addPath(cgPath)
                    }
                }
            }
            ctx.cgContext.strokePath()
        }
    }
}
