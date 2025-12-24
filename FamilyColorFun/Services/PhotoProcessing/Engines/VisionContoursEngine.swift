import UIKit
@preconcurrency import Vision
import CoreImage
import Accelerate

/// Vision framework-based line art extraction engine
final class VisionContoursEngine: LineArtEngineProtocol {
    private let preprocessor = ImagePreprocessor()

    var engineName: String { "VisionContours" }
    var isAvailable: Bool { true }  // Available on iOS 14+

    func extractLines(from photo: UIImage, settings: LineArtSettings) async throws -> UIImage {
        // 1. Preprocess
        let preprocessed = preprocessor.preprocess(photo, settings: settings)

        // 2. Detect polarity
        let isDarkOnLight = preprocessor.detectPolarity(preprocessed)

        // 3. Extract contours using Vision
        let contourImage = try await detectContours(preprocessed, settings: settings, darkOnLight: isDarkOnLight)

        // 4. Apply fillability post-processing
        let processed = fillabilityPostProcess(contourImage, settings: settings)

        return processed
    }

    private func detectContours(_ image: UIImage, settings: LineArtSettings, darkOnLight: Bool) async throws -> UIImage {
        guard let cgImage = image.cgImage else {
            throw LineArtError.invalidImage
        }

        let request = VNDetectContoursRequest()
        request.contrastAdjustment = settings.contrastAdjustment
        request.detectsDarkOnLight = darkOnLight
        request.maximumImageDimension = settings.maxDimension

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])

                    guard let observation = request.results?.first else {
                        continuation.resume(throwing: LineArtError.noContoursDetected)
                        return
                    }

                    let contourImage = self.renderContours(observation, size: image.size)
                    continuation.resume(returning: contourImage)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
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

            // Render all contours
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

    private func fillabilityPostProcess(_ image: UIImage, settings: LineArtSettings) -> UIImage {
        guard image.cgImage != nil else { return image }

        var result = image

        // Step A: Two-stage morphology
        result = morphologicalClose(result, kernelSize: 1)  // Stage 1: seal micro-gaps

        if settings.closeLargeGaps {
            result = morphologicalClose(result, kernelSize: settings.largeGapKernel)  // Stage 2

            // For toddler mode, apply additional closing to ensure 100% closure
            if settings.simplifyRegions {
                result = morphologicalClose(result, kernelSize: settings.largeGapKernel / 2)
            }
        }

        // Step B: Thicken lines
        result = morphologicalDilate(result, amount: settings.thickness)

        // Step C: Edge hardening - pure binary
        result = hardThreshold(result, level: 128)

        // Step D: Remove tiny speckle components
        // Use minRegionArea from settings (larger for toddler mode)
        let minArea = settings.simplifyRegions ? settings.minRegionArea : 30
        result = removeTinyComponents(result, minArea: minArea)

        // Step E: Simplify regions for toddler mode
        // This fills in tiny enclosed areas to reduce region count
        if settings.simplifyRegions {
            result = simplifySmallRegions(result, minArea: settings.minRegionArea)
        }

        return result
    }

    // MARK: - Morphological Operations

    private func morphologicalClose(_ image: UIImage, kernelSize: Int) -> UIImage {
        // Close = dilate then erode (fills small holes)
        var result = morphologicalDilate(image, amount: kernelSize)
        result = morphologicalErode(result, amount: kernelSize)
        return result
    }

    private func morphologicalDilate(_ image: UIImage, amount: Int) -> UIImage {
        guard amount > 0, let cgImage = image.cgImage else { return image }

        let width = cgImage.width
        let height = cgImage.height

        guard let context = createGrayscaleContext(width: width, height: height),
              let pixels = context.data else { return image }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var src = vImage_Buffer(data: pixels, height: vImagePixelCount(height),
                                width: vImagePixelCount(width), rowBytes: width)
        var dest = vImage_Buffer(data: malloc(width * height), height: vImagePixelCount(height),
                                 width: vImagePixelCount(width), rowBytes: width)

        let kernelSize = amount * 2 + 1
        // Create a kernel filled with zeros for minimum operation (dilates black on white background)
        var kernel = [UInt8](repeating: 0, count: kernelSize * kernelSize)

        // For white background/black lines: dilate = expand black using min filter
        kernel.withUnsafeBufferPointer { kernelPtr in
            vImageDilate_Planar8(&src, &dest, 0, 0, kernelPtr.baseAddress!,
                                 vImagePixelCount(kernelSize), vImagePixelCount(kernelSize),
                                 vImage_Flags(kvImageNoFlags))
        }

        if let outputCGImage = createCGImage(from: dest, width: width, height: height) {
            free(dest.data)
            return UIImage(cgImage: outputCGImage)
        }

        free(dest.data)
        return image
    }

    private func morphologicalErode(_ image: UIImage, amount: Int) -> UIImage {
        guard amount > 0, let cgImage = image.cgImage else { return image }

        let width = cgImage.width
        let height = cgImage.height

        guard let context = createGrayscaleContext(width: width, height: height),
              let pixels = context.data else { return image }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var src = vImage_Buffer(data: pixels, height: vImagePixelCount(height),
                                width: vImagePixelCount(width), rowBytes: width)
        var dest = vImage_Buffer(data: malloc(width * height), height: vImagePixelCount(height),
                                 width: vImagePixelCount(width), rowBytes: width)

        let kernelSize = amount * 2 + 1
        // Create a kernel filled with zeros for max operation (erodes black on white background)
        var kernel = [UInt8](repeating: 0, count: kernelSize * kernelSize)

        kernel.withUnsafeBufferPointer { kernelPtr in
            vImageErode_Planar8(&src, &dest, 0, 0, kernelPtr.baseAddress!,
                                vImagePixelCount(kernelSize), vImagePixelCount(kernelSize),
                                vImage_Flags(kvImageNoFlags))
        }

        if let outputCGImage = createCGImage(from: dest, width: width, height: height) {
            free(dest.data)
            return UIImage(cgImage: outputCGImage)
        }

        free(dest.data)
        return image
    }

    private func hardThreshold(_ image: UIImage, level: UInt8) -> UIImage {
        guard let cgImage = image.cgImage else { return image }

        let width = cgImage.width
        let height = cgImage.height

        guard let context = createGrayscaleContext(width: width, height: height),
              let pixels = context.data?.assumingMemoryBound(to: UInt8.self) else { return image }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        for i in 0..<(width * height) {
            pixels[i] = pixels[i] < level ? 0 : 255
        }

        if let outputCGImage = context.makeImage() {
            return UIImage(cgImage: outputCGImage)
        }
        return image
    }

    private func removeTinyComponents(_ image: UIImage, minArea: Int) -> UIImage {
        // Simple implementation: threshold + morphological opening
        // A full connected components analysis would be more accurate but slower
        guard let cgImage = image.cgImage else { return image }

        let width = cgImage.width
        let height = cgImage.height

        // For very small images, skip this step
        if width * height < 10000 { return image }

        // Apply small morphological opening to remove noise
        let kernelSize = max(1, Int(sqrt(Double(minArea)) / 3))
        var result = morphologicalErode(image, amount: kernelSize)
        result = morphologicalDilate(result, amount: kernelSize)

        return result
    }

    /// Simplify small regions by filling them with black (merging into lines)
    /// This reduces the total region count for toddler mode
    private func simplifySmallRegions(_ image: UIImage, minArea: Int) -> UIImage {
        guard let cgImage = image.cgImage else { return image }

        let width = cgImage.width
        let height = cgImage.height

        // Get grayscale pixels
        guard let context = createGrayscaleContext(width: width, height: height),
              let pixels = context.data?.assumingMemoryBound(to: UInt8.self) else {
            return image
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Create working copy
        var pixelsCopy = [UInt8](repeating: 0, count: width * height)
        for i in 0..<(width * height) {
            pixelsCopy[i] = pixels[i]
        }

        // Find white regions (fillable areas) and fill small ones with black
        var visited = [Bool](repeating: false, count: width * height)

        for y in 0..<height {
            for x in 0..<width {
                let idx = y * width + x
                if pixelsCopy[idx] > 200 && !visited[idx] {  // White pixel, unvisited
                    // Flood fill to find region and its area
                    var regionPixels: [(Int, Int)] = []
                    var stack = [(x, y)]

                    while !stack.isEmpty {
                        let (cx, cy) = stack.removeLast()
                        if cx < 0 || cx >= width || cy < 0 || cy >= height { continue }

                        let cidx = cy * width + cx
                        if visited[cidx] || pixelsCopy[cidx] <= 200 { continue }

                        visited[cidx] = true
                        regionPixels.append((cx, cy))

                        stack.append((cx + 1, cy))
                        stack.append((cx - 1, cy))
                        stack.append((cx, cy + 1))
                        stack.append((cx, cy - 1))
                    }

                    // If region is too small, fill it with black
                    if regionPixels.count < minArea && regionPixels.count > 0 {
                        for (px, py) in regionPixels {
                            let pidx = py * width + px
                            pixels[pidx] = 0  // Fill with black
                        }
                    }
                }
            }
        }

        if let outputCGImage = context.makeImage() {
            return UIImage(cgImage: outputCGImage)
        }
        return image
    }

    // MARK: - Helper Methods

    private func createGrayscaleContext(width: Int, height: Int) -> CGContext? {
        return CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        )
    }

    private func createCGImage(from buffer: vImage_Buffer, width: Int, height: Int) -> CGImage? {
        guard let context = CGContext(
            data: buffer.data,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return nil }

        return context.makeImage()
    }
}

// MARK: - Errors

enum LineArtError: Error {
    case invalidImage
    case noContoursDetected
    case processingFailed
}
