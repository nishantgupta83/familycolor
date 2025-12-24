import UIKit
import Accelerate

/// Shared post-processor for all line art engines
/// Converts EdgeMap to fillable line art using morphological operations
/// All engines share this code - no duplication
final class LineArtPostProcessor {

    // MARK: - Public API

    /// Process an edge map into fillable line art
    /// - Parameters:
    ///   - edgeMap: Raw edge output from engine
    ///   - settings: Processing settings
    /// - Returns: Processed line art intermediate
    func process(edgeMap: EdgeMap, settings: LineArtSettings) -> LineArtIntermediate {
        guard let cgImage = UIImage(cgImage: edgeMap.data).cgImage else {
            return LineArtIntermediate(
                lineImage: UIImage(cgImage: edgeMap.data),
                lineThickness: 1,
                regionEstimate: 0,
                postProcessingApplied: []
            )
        }

        var result = UIImage(cgImage: cgImage)
        var operations: [String] = []

        // 1. Binarize (if needed)
        if !edgeMap.isBinary {
            let threshold = adjustThreshold(
                suggested: edgeMap.engineMeta.suggestedThreshold,
                density: edgeMap.engineMeta.edgeDensity,
                settings: settings
            )
            result = binarize(result, threshold: threshold)
            operations.append("binarize(\(String(format: "%.2f", threshold)))")
        }

        // 2. Morphological close (seal gaps)
        let closeKernel = settings.postProcess.closeKernel
        if closeKernel > 0 {
            result = morphologicalClose(result, kernelSize: closeKernel)
            operations.append("close(\(closeKernel))")
        }

        // Additional closing for toddler mode
        if settings.postProcess.simplifyRegions {
            let extraClose = max(1, closeKernel / 2)
            result = morphologicalClose(result, kernelSize: extraClose)
            operations.append("close(\(extraClose))")
        }

        // 3. Compute region estimate AFTER close, BEFORE dilation
        let regionEstimate = estimateRegionCount(result)

        // 4. Dilate to target thickness
        let thickness = settings.postProcess.thickness
        if thickness > 1 {
            result = morphologicalDilate(result, amount: thickness)
            operations.append("dilate(\(thickness))")
        }

        // 5. Hard threshold (ensure pure binary)
        result = hardThreshold(result, level: 128)
        operations.append("threshold(128)")

        // 6. Remove speckles
        let minSpeckle = settings.postProcess.minSpeckleArea
        if minSpeckle > 0 {
            result = removeTinyComponents(result, minArea: minSpeckle)
            operations.append("removeSpeckles(\(minSpeckle))")
        }

        // 7. Simplify regions (toddler mode)
        if settings.postProcess.simplifyRegions {
            let minRegion = settings.postProcess.minRegionArea
            result = simplifySmallRegions(result, minArea: minRegion)
            operations.append("simplify(\(minRegion))")
        }

        return LineArtIntermediate(
            lineImage: result,
            lineThickness: thickness,
            regionEstimate: regionEstimate,
            postProcessingApplied: operations
        )
    }

    // MARK: - Threshold Adjustment

    /// Auto-adjust threshold for toddler mode when edge density is high
    private func adjustThreshold(
        suggested: Float,
        density: Float,
        settings: LineArtSettings
    ) -> Float {
        // For toddler mode with high density, raise threshold to get fewer edges
        if settings.postProcess.simplifyRegions && density > 0.15 {
            return min(0.9, suggested + 0.2)
        }
        return suggested
    }

    // MARK: - Binarization

    private func binarize(_ image: UIImage, threshold: Float) -> UIImage {
        guard let cgImage = image.cgImage else { return image }

        let width = cgImage.width
        let height = cgImage.height
        let thresholdValue = UInt8(threshold * 255)

        guard let context = createGrayscaleContext(width: width, height: height),
              let pixels = context.data?.assumingMemoryBound(to: UInt8.self) else {
            return image
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        for i in 0..<(width * height) {
            pixels[i] = pixels[i] < thresholdValue ? 0 : 255
        }

        if let outputCGImage = context.makeImage() {
            return UIImage(cgImage: outputCGImage)
        }
        return image
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
        var kernel = [UInt8](repeating: 0, count: kernelSize * kernelSize)

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

    // MARK: - Noise Removal

    private func removeTinyComponents(_ image: UIImage, minArea: Int) -> UIImage {
        guard let cgImage = image.cgImage else { return image }

        let width = cgImage.width
        let height = cgImage.height

        if width * height < 10000 { return image }

        let kernelSize = max(1, Int(sqrt(Double(minArea)) / 3))
        var result = morphologicalErode(image, amount: kernelSize)
        result = morphologicalDilate(result, amount: kernelSize)

        return result
    }

    private func simplifySmallRegions(_ image: UIImage, minArea: Int) -> UIImage {
        guard let cgImage = image.cgImage else { return image }

        let width = cgImage.width
        let height = cgImage.height

        guard let context = createGrayscaleContext(width: width, height: height),
              let pixels = context.data?.assumingMemoryBound(to: UInt8.self) else {
            return image
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var pixelsCopy = [UInt8](repeating: 0, count: width * height)
        for i in 0..<(width * height) {
            pixelsCopy[i] = pixels[i]
        }

        var visited = [Bool](repeating: false, count: width * height)

        for y in 0..<height {
            for x in 0..<width {
                let idx = y * width + x
                if pixelsCopy[idx] > 200 && !visited[idx] {
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

                    if regionPixels.count < minArea && regionPixels.count > 0 {
                        for (px, py) in regionPixels {
                            let pidx = py * width + px
                            pixels[pidx] = 0
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

    // MARK: - Region Estimation

    /// Estimate region count (computed AFTER close, BEFORE dilation)
    private func estimateRegionCount(_ image: UIImage) -> Int {
        guard let cgImage = image.cgImage else { return 0 }

        let width = cgImage.width
        let height = cgImage.height

        guard let context = createGrayscaleContext(width: width, height: height),
              let pixels = context.data?.assumingMemoryBound(to: UInt8.self) else {
            return 0
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var visited = [Bool](repeating: false, count: width * height)
        var regionCount = 0

        // Count white regions (fillable areas)
        for y in 0..<height {
            for x in 0..<width {
                let idx = y * width + x
                if pixels[idx] > 200 && !visited[idx] {
                    // Found a new region - flood fill to mark it
                    var stack = [(x, y)]
                    var pixelCount = 0

                    while !stack.isEmpty {
                        let (cx, cy) = stack.removeLast()
                        if cx < 0 || cx >= width || cy < 0 || cy >= height { continue }

                        let cidx = cy * width + cx
                        if visited[cidx] || pixels[cidx] <= 200 { continue }

                        visited[cidx] = true
                        pixelCount += 1

                        stack.append((cx + 1, cy))
                        stack.append((cx - 1, cy))
                        stack.append((cx, cy + 1))
                        stack.append((cx, cy - 1))
                    }

                    // Only count regions above minimum threshold
                    if pixelCount >= 100 {
                        regionCount += 1
                    }
                }
            }
        }

        return regionCount
    }

    // MARK: - Helper Methods

    private func createGrayscaleContext(width: Int, height: Int) -> CGContext? {
        CGContext(
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
