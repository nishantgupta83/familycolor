import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

/// Handles image preprocessing for line art extraction
struct ImagePreprocessor {
    private let context = CIContext()

    /// Resize image to max dimension while maintaining aspect ratio
    func resize(_ image: UIImage, maxDimension: Int) -> UIImage {
        let maxDim = CGFloat(maxDimension)
        let size = image.size
        let scale = min(maxDim / size.width, maxDim / size.height, 1.0)

        if scale >= 1.0 { return image }

        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    /// Increase contrast using gamma adjustment
    func enhanceContrast(_ image: UIImage, boost: Float) -> UIImage {
        guard let ciImage = CIImage(image: image) else { return image }

        let filter = CIFilter.colorControls()
        filter.inputImage = ciImage
        filter.contrast = boost

        guard let output = filter.outputImage,
              let cgImage = context.createCGImage(output, from: output.extent) else {
            return image
        }
        return UIImage(cgImage: cgImage)
    }

    /// Light denoise using median filter
    func denoise(_ image: UIImage) -> UIImage {
        guard let ciImage = CIImage(image: image) else { return image }

        let filter = CIFilter.median()
        filter.inputImage = ciImage

        guard let output = filter.outputImage,
              let cgImage = context.createCGImage(output, from: output.extent) else {
            return image
        }
        return UIImage(cgImage: cgImage)
    }

    /// Detect if image is dark-on-light or light-on-dark
    func detectPolarity(_ image: UIImage) -> Bool {
        guard let cgImage = image.cgImage else { return true }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width

        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return true }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Sample corners and calculate average brightness
        var totalBrightness: Int = 0
        let sampleSize = 20

        for y in 0..<sampleSize {
            for x in 0..<sampleSize {
                let offset = (y * width + x) * bytesPerPixel
                totalBrightness += Int(pixelData[offset]) + Int(pixelData[offset + 1]) + Int(pixelData[offset + 2])
            }
        }

        let avgBrightness = totalBrightness / (sampleSize * sampleSize * 3)
        return avgBrightness > 127  // Light background = dark on light
    }

    /// Full preprocessing pipeline
    func preprocess(_ image: UIImage, settings: LineArtSettings) -> UIImage {
        var result = resize(image, maxDimension: settings.maxDimension)
        result = enhanceContrast(result, boost: settings.contrastBoost)
        result = denoise(result)
        return result
    }
}
