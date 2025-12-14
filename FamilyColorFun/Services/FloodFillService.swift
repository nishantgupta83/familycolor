import UIKit
import SwiftUI

class FloodFillService {
    static func floodFill(
        image: UIImage,
        at point: CGPoint,
        with color: UIColor,
        tolerance: Int = 32
    ) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        let width = cgImage.width
        let height = cgImage.height

        // Ensure point is within bounds
        let x = Int(point.x * CGFloat(width) / image.size.width)
        let y = Int(point.y * CGFloat(height) / image.size.height)

        guard x >= 0, x < width, y >= 0, y < height else { return nil }

        // Create bitmap context
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8

        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Get target color at point
        let targetIndex = (y * width + x) * bytesPerPixel
        let targetR = pixelData[targetIndex]
        let targetG = pixelData[targetIndex + 1]
        let targetB = pixelData[targetIndex + 2]
        let targetA = pixelData[targetIndex + 3]

        // Get fill color components
        var fillR: CGFloat = 0, fillG: CGFloat = 0, fillB: CGFloat = 0, fillA: CGFloat = 0
        color.getRed(&fillR, green: &fillG, blue: &fillB, alpha: &fillA)

        let newR = UInt8(fillR * 255)
        let newG = UInt8(fillG * 255)
        let newB = UInt8(fillB * 255)
        let newA = UInt8(fillA * 255)

        // Don't fill if already the same color
        if targetR == newR && targetG == newG && targetB == newB {
            return image
        }

        // Flood fill using queue-based algorithm
        var queue = [(Int, Int)]()
        var visited = Set<Int>()

        queue.append((x, y))

        while !queue.isEmpty {
            let (cx, cy) = queue.removeFirst()

            let index = cy * width + cx
            if visited.contains(index) { continue }

            let pixelIndex = index * bytesPerPixel
            let r = pixelData[pixelIndex]
            let g = pixelData[pixelIndex + 1]
            let b = pixelData[pixelIndex + 2]
            let a = pixelData[pixelIndex + 3]

            // Check if color matches within tolerance
            let matches = abs(Int(r) - Int(targetR)) <= tolerance &&
                         abs(Int(g) - Int(targetG)) <= tolerance &&
                         abs(Int(b) - Int(targetB)) <= tolerance &&
                         abs(Int(a) - Int(targetA)) <= tolerance

            if !matches {
                continue
            }

            visited.insert(index)

            // Fill pixel
            pixelData[pixelIndex] = newR
            pixelData[pixelIndex + 1] = newG
            pixelData[pixelIndex + 2] = newB
            pixelData[pixelIndex + 3] = newA

            // Add neighbors
            if cx > 0 { queue.append((cx - 1, cy)) }
            if cx < width - 1 { queue.append((cx + 1, cy)) }
            if cy > 0 { queue.append((cx, cy - 1)) }
            if cy < height - 1 { queue.append((cx, cy + 1)) }
        }

        // Create new image from modified pixel data
        guard let newContext = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ),
        let newCGImage = newContext.makeImage() else {
            return nil
        }

        return UIImage(cgImage: newCGImage)
    }

    /// Apply color to all pixels where label-map has the specified region ID.
    /// Uses pre-computed label-map for O(n) pixel fill without runtime flood.
    static func applyMaskFill(
        image: UIImage,
        labelMapBuffer: [UInt8],
        width labelWidth: Int,
        height labelHeight: Int,
        regionId: Int,
        color: UIColor
    ) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        let width = cgImage.width
        let height = cgImage.height

        // Label-map and image must match dimensions
        guard width == labelWidth && height == labelHeight else {
            print("Warning: Image size (\(width)x\(height)) doesn't match label-map (\(labelWidth)x\(labelHeight))")
            return nil
        }

        // Create bitmap context for the main image
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8

        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Get fill color components
        var fillR: CGFloat = 0, fillG: CGFloat = 0, fillB: CGFloat = 0, fillA: CGFloat = 0
        color.getRed(&fillR, green: &fillG, blue: &fillB, alpha: &fillA)

        let newR = UInt8(fillR * 255)
        let newG = UInt8(fillG * 255)
        let newB = UInt8(fillB * 255)
        let newA = UInt8(fillA * 255)

        // Apply color to all pixels where label-map matches regionId
        let targetValue = UInt8(regionId)
        for y in 0..<height {
            for x in 0..<width {
                let labelIndex = y * labelWidth + x
                if labelMapBuffer[labelIndex] == targetValue {
                    let pixelIndex = (y * width + x) * bytesPerPixel
                    pixelData[pixelIndex] = newR
                    pixelData[pixelIndex + 1] = newG
                    pixelData[pixelIndex + 2] = newB
                    pixelData[pixelIndex + 3] = newA
                }
            }
        }

        // Create new image from modified pixel data
        guard let newContext = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ),
        let newCGImage = newContext.makeImage() else {
            return nil
        }

        return UIImage(cgImage: newCGImage)
    }

    static func calculateProgress(for image: UIImage) -> Double {
        guard let cgImage = image.cgImage else { return 0 }

        let width = cgImage.width
        let height = cgImage.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width

        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return 0 }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var coloredPixels = 0
        var totalPixels = 0

        for i in stride(from: 0, to: pixelData.count, by: bytesPerPixel) {
            let r = pixelData[i]
            let g = pixelData[i + 1]
            let b = pixelData[i + 2]
            let a = pixelData[i + 3]

            // Skip transparent pixels
            guard a > 128 else { continue }

            totalPixels += 1

            // Check if pixel is not white (has been colored)
            let isWhite = r > 240 && g > 240 && b > 240
            if !isWhite {
                coloredPixels += 1
            }
        }

        guard totalPixels > 0 else { return 0 }
        return Double(coloredPixels) / Double(totalPixels)
    }
}
