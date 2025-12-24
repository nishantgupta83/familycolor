import CoreGraphics
import CoreML
import UIKit

/// HED (Holistically-Nested Edge Detection) engine using CoreML
/// Produces cleaner, more consistent edges than Vision framework
/// Requires HED_fuse.mlmodel (~7MB) to be available
final class HEDEngine: LineArtExtractorProtocol {
    var engineName: String { "HED Deep Edges" }

    /// HED requires the CoreML model to be loaded
    var isAvailable: Bool { model != nil }

    /// HED works best at 480x480
    var preferredInputSize: Int { 480 }

    // MARK: - Private Properties

    /// Lazy-loaded CoreML model
    private var model: MLModel? {
        if _modelLoaded { return _model }
        _modelLoaded = true
        _model = loadModel()
        return _model
    }

    private var _model: MLModel?
    private var _modelLoaded = false

    // MARK: - Extraction

    func extractEdges(
        from preprocessedImage: CGImage,
        settings: LineArtSettings
    ) async throws -> EdgeMap {
        guard let model = model else {
            throw ProcessingError.engineNotAvailable(.hed)
        }

        let startTime = CFAbsoluteTimeGetCurrent()

        // Convert CGImage to CVPixelBuffer
        let pixelBuffer = try createPixelBuffer(from: preprocessedImage)

        // Run inference
        let output = try await runInference(model: model, input: pixelBuffer)

        // Convert output to CGImage
        let edgeImage = try convertOutputToImage(output, size: CGSize(
            width: preprocessedImage.width,
            height: preprocessedImage.height
        ))

        let processingTime = Int((CFAbsoluteTimeGetCurrent() - startTime) * 1000)

        // Compute edge density
        let edgeDensity = EdgeMap.computeEdgeDensity(from: edgeImage, isBinary: false)

        let meta = EngineMeta(
            engineName: engineName,
            suggestedThreshold: 0.5,  // Probability map needs thresholding
            edgeDensity: edgeDensity,
            processingTimeMs: processingTime,
            originalScale: 1.0
        )

        return EdgeMap(
            data: edgeImage,
            isBinary: false,  // HED outputs probability map
            engineMeta: meta
        )
    }

    // MARK: - Model Loading

    private func loadModel() -> MLModel? {
        // Try to load HED_fuse.mlmodel from bundle
        guard let modelURL = Bundle.main.url(forResource: "HED_fuse", withExtension: "mlmodelc") else {
            print("HEDEngine: HED_fuse.mlmodelc not found in bundle")
            return nil
        }

        do {
            let config = MLModelConfiguration()
            config.computeUnits = .cpuAndNeuralEngine  // Use Neural Engine when available
            return try MLModel(contentsOf: modelURL, configuration: config)
        } catch {
            print("HEDEngine: Failed to load model: \(error)")
            return nil
        }
    }

    // MARK: - Pixel Buffer Conversion

    private func createPixelBuffer(from image: CGImage) throws -> CVPixelBuffer {
        let width = preferredInputSize
        let height = preferredInputSize

        var pixelBuffer: CVPixelBuffer?
        let attrs: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]

        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            attrs as CFDictionary,
            &pixelBuffer
        )

        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            throw ProcessingError.preprocessingFailed("Failed to create pixel buffer")
        }

        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }

        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ) else {
            throw ProcessingError.preprocessingFailed("Failed to create context for pixel buffer")
        }

        // Draw image resized to 480x480
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        return buffer
    }

    // MARK: - Inference

    private func runInference(model: MLModel, input: CVPixelBuffer) async throws -> MLMultiArray {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    // Create feature provider with input
                    let inputFeatures = try MLDictionaryFeatureProvider(dictionary: [
                        "data": MLFeatureValue(pixelBuffer: input)
                    ])

                    // Run prediction
                    let output = try model.prediction(from: inputFeatures)

                    // Get output array
                    guard let outputArray = output.featureValue(for: "fuse")?.multiArrayValue else {
                        continuation.resume(throwing: ProcessingError.extractionFailed("Missing output array"))
                        return
                    }

                    continuation.resume(returning: outputArray)
                } catch {
                    continuation.resume(throwing: ProcessingError.extractionFailed(error.localizedDescription))
                }
            }
        }
    }

    // MARK: - Output Conversion

    private func convertOutputToImage(_ output: MLMultiArray, size: CGSize) throws -> CGImage {
        let outputWidth = output.shape[2].intValue
        let outputHeight = output.shape[1].intValue

        // Create grayscale image from output
        var pixels = [UInt8](repeating: 0, count: outputWidth * outputHeight)

        // Normalize output values to 0-255
        var minVal: Float = Float.greatestFiniteMagnitude
        var maxVal: Float = -Float.greatestFiniteMagnitude

        for i in 0..<(outputWidth * outputHeight) {
            let val = output[i].floatValue
            minVal = min(minVal, val)
            maxVal = max(maxVal, val)
        }

        let range = maxVal - minVal
        if range > 0 {
            for i in 0..<(outputWidth * outputHeight) {
                let normalized = (output[i].floatValue - minVal) / range
                // Invert if needed (detect by mean)
                pixels[i] = UInt8(normalized * 255)
            }
        }

        // Check if we need to invert (edges should be dark on light)
        let mean = pixels.reduce(0, { $0 + Int($1) }) / pixels.count
        if mean < 128 {
            // Invert: edges are currently light on dark
            for i in 0..<pixels.count {
                pixels[i] = 255 - pixels[i]
            }
        }

        // Create CGImage
        guard let context = CGContext(
            data: &pixels,
            width: outputWidth,
            height: outputHeight,
            bitsPerComponent: 8,
            bytesPerRow: outputWidth,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else {
            throw ProcessingError.extractionFailed("Failed to create output image context")
        }

        guard let cgImage = context.makeImage() else {
            throw ProcessingError.extractionFailed("Failed to create output image")
        }

        // Resize to target size if needed
        if outputWidth != Int(size.width) || outputHeight != Int(size.height) {
            return resizeImage(cgImage, to: size)
        }

        return cgImage
    }

    private func resizeImage(_ image: CGImage, to size: CGSize) -> CGImage {
        guard let context = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: Int(size.width),
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else {
            return image
        }

        context.interpolationQuality = .high
        context.draw(image, in: CGRect(origin: .zero, size: size))

        return context.makeImage() ?? image
    }
}
