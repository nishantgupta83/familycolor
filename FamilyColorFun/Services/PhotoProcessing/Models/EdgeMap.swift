import CoreGraphics
import Foundation

/// Metadata about the edge extraction process
struct EngineMeta: Equatable {
    /// Name of the engine that produced this output
    let engineName: String

    /// Suggested threshold for binarization (0.0-1.0)
    /// For probability maps, this is the recommended cutoff
    let suggestedThreshold: Float

    /// Edge density: fraction of pixels > 0.3 (probability) or white (binary)
    /// Computed BEFORE morphology to reflect raw model output
    /// Used to auto-adjust threshold in toddler mode when > 0.15
    let edgeDensity: Float

    /// Processing time in milliseconds
    let processingTimeMs: Int

    /// Original scale factor (for scaling back up if needed)
    let originalScale: CGFloat
}

/// Output from a line art extraction engine
/// Engines return EdgeMap, not UIImage - keeps them pure (no post-processing)
struct EdgeMap: Equatable {
    /// Grayscale edge probability map or binary edge image
    let data: CGImage

    /// True if already thresholded to binary (black/white only)
    /// False if probability map (grayscale values 0.0-1.0)
    let isBinary: Bool

    /// Engine diagnostics and metadata
    let engineMeta: EngineMeta

    /// Width of the edge map
    var width: Int { data.width }

    /// Height of the edge map
    var height: Int { data.height }
}

extension EdgeMap {
    /// Compute edge density from a CGImage
    /// - Parameter image: Grayscale image (probability or binary)
    /// - Parameter isBinary: Whether image is already binary
    /// - Returns: Fraction of edge pixels (0.0-1.0)
    static func computeEdgeDensity(from image: CGImage, isBinary: Bool) -> Float {
        let width = image.width
        let height = image.height
        let totalPixels = width * height

        guard totalPixels > 0 else { return 0 }

        // Create bitmap context to read pixels
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return 0 }

        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let data = context.data else { return 0 }
        let pixels = data.bindMemory(to: UInt8.self, capacity: totalPixels)

        var edgeCount = 0
        let threshold: UInt8 = isBinary ? 128 : 77  // 77 ≈ 0.3 * 255

        for i in 0..<totalPixels {
            if pixels[i] > threshold {
                edgeCount += 1
            }
        }

        return Float(edgeCount) / Float(totalPixels)
    }
}
