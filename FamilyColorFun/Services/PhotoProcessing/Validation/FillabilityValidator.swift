import UIKit
import Accelerate

/// Validates line art for fillability (how well regions can be colored)
final class FillabilityValidator {
    // Canonical resolution for consistent metrics
    private let canonicalSize: CGFloat = 512
    private let targetLineWidth: CGFloat = 2.5
    private let minTapArea: Int = 500  // Minimum pixels for kid-friendly tapping

    // Toddler mode thresholds (larger tap targets, fewer regions)
    private let toddlerMinTapArea: Int = 2000
    private let toddlerMaxRegions: Int = 30
    private let toddlerMinRegions: Int = 5

    // MARK: - Public API

    /// Evaluate the fillability of a line art image
    func evaluate(_ lineArt: UIImage) -> FillabilityResult {
        return evaluate(lineArt, forToddler: false)
    }

    /// Evaluate with toddler-specific thresholds
    func evaluate(_ lineArt: UIImage, forToddler: Bool) -> FillabilityResult {
        // Normalize to canonical size
        guard let normalized = normalize(lineArt) else {
            return .skipped
        }

        // Calculate metrics
        let regions = regionCount(normalized)
        let endpoints = endpointScore(normalized)
        let leaks = leakPotential(normalized)
        let closure = closureRate(normalized, regionCount: regions)

        // Use different tap area based on mode
        let tapArea = forToddler ? toddlerMinTapArea : minTapArea
        let tappable = tapUsability(normalized, minTapArea: tapArea)

        // Calculate overall score (weighted average)
        // For toddler mode, closure and tappability are more important
        let score: Double
        if forToddler {
            score = (endpoints * 0.1) +
                    ((1.0 - leaks) * 0.3) +
                    (closure * 0.35) +
                    (tappable * 0.25)
        } else {
            score = (endpoints * 0.2) +
                    ((1.0 - leaks) * 0.3) +
                    (closure * 0.3) +
                    (tappable * 0.2)
        }

        // Generate suggestions based on mode
        var suggestions: [String] = []

        if forToddler {
            // Toddler-specific suggestions
            if regions > toddlerMaxRegions {
                suggestions.append("Too many areas - try a simpler photo")
            }
            if regions < toddlerMinRegions {
                suggestions.append("Not enough areas to color")
            }
            if leaks > 0.3 {
                suggestions.append("Some colors may leak - try a different photo")
            }
            if closure < 0.9 {
                suggestions.append("Some areas may not fill completely")
            }
            if tappable < 0.9 {
                suggestions.append("Some areas may be too small for little fingers")
            }
        } else {
            // Standard suggestions
            if regions > 500 {
                suggestions.append("Try reducing detail")
            }
            if regions < 10 {
                suggestions.append("Try increasing detail")
            }
            if leaks > 0.5 {
                suggestions.append("Try increasing thickness")
            }
            if closure < 0.7 {
                suggestions.append("Some areas may not fill perfectly")
            }
            if tappable < 0.8 {
                suggestions.append("Some regions are very small")
            }
        }

        return FillabilityResult(
            score: score,
            regionCount: regions,
            closureRate: closure,
            leakPotential: leaks,
            tapUsability: tappable,
            suggestions: suggestions
        )
    }

    // MARK: - Normalization

    /// Resize to canonical size and normalize line width
    private func normalize(_ lineArt: UIImage) -> UIImage? {
        guard let cgImage = lineArt.cgImage else { return nil }

        let originalWidth = CGFloat(cgImage.width)
        let originalHeight = CGFloat(cgImage.height)
        let scale = canonicalSize / max(originalWidth, originalHeight)

        let newWidth = Int(originalWidth * scale)
        let newHeight = Int(originalHeight * scale)

        UIGraphicsBeginImageContextWithOptions(CGSize(width: newWidth, height: newHeight), false, 1.0)
        defer { UIGraphicsEndImageContext() }

        lineArt.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        return UIGraphicsGetImageFromCurrentImageContext()
    }

    // MARK: - Metrics

    /// Count distinct fillable regions
    private func regionCount(_ image: UIImage) -> Int {
        guard let cgImage = image.cgImage else { return 0 }

        let width = cgImage.width
        let height = cgImage.height

        guard let pixelData = getGrayscalePixels(cgImage) else { return 0 }

        // Invert: white background becomes fillable (1), black lines become 0
        var inverted = [UInt8](repeating: 0, count: width * height)
        for i in 0..<(width * height) {
            inverted[i] = pixelData[i] > 200 ? 1 : 0
        }

        // Use simple flood fill to count connected components
        var visited = [Bool](repeating: false, count: width * height)
        var count = 0

        for y in 0..<height {
            for x in 0..<width {
                let idx = y * width + x
                if inverted[idx] == 1 && !visited[idx] {
                    // Found a new region
                    let area = floodFillArea(inverted: &inverted, visited: &visited,
                                             x: x, y: y, width: width, height: height)
                    if area >= 20 {  // Ignore tiny speckles
                        count += 1
                    }
                }
            }
        }

        return count
    }

    /// Score based on line endpoint continuity (fewer endpoints = more closed shapes)
    private func endpointScore(_ image: UIImage) -> Double {
        guard let cgImage = image.cgImage else { return 1.0 }

        let width = cgImage.width
        let height = cgImage.height

        guard let pixelData = getGrayscalePixels(cgImage) else { return 1.0 }

        var endpointCount = 0

        // Simple endpoint detection: count pixels that have only 1 black neighbor
        for y in 1..<(height - 1) {
            for x in 1..<(width - 1) {
                let idx = y * width + x
                if pixelData[idx] < 128 {  // Black pixel (line)
                    var neighbors = 0
                    // Check 8 neighbors
                    for dy in -1...1 {
                        for dx in -1...1 {
                            if dx == 0 && dy == 0 { continue }
                            let nIdx = (y + dy) * width + (x + dx)
                            if pixelData[nIdx] < 128 {
                                neighbors += 1
                            }
                        }
                    }
                    if neighbors == 1 {
                        endpointCount += 1
                    }
                }
            }
        }

        // Normalize: 0 endpoints = 1.0, 100+ endpoints = 0.0
        return max(0, 1.0 - Double(endpointCount) / 100.0)
    }

    /// Estimate leak potential using corner flood fills
    private func leakPotential(_ image: UIImage) -> Double {
        guard let cgImage = image.cgImage else { return 0.0 }

        let width = cgImage.width
        let height = cgImage.height

        guard let pixelData = getGrayscalePixels(cgImage) else { return 0.0 }

        // Invert for flood fill
        var inverted = [UInt8](repeating: 0, count: width * height)
        for i in 0..<(width * height) {
            inverted[i] = pixelData[i] > 200 ? 1 : 0
        }

        // Sample from corners
        let samplePoints = [
            (0, 0), (width - 1, 0),
            (0, height - 1), (width - 1, height - 1)
        ]

        var leakScores: [Double] = []

        for (x, y) in samplePoints {
            var visited = [Bool](repeating: false, count: width * height)
            let area = floodFillArea(inverted: &inverted, visited: &visited,
                                     x: x, y: y, width: width, height: height)
            let maxExpected = Double(width * height) * 0.3
            leakScores.append(min(1.0, Double(area) / maxExpected))
        }

        return leakScores.reduce(0, +) / Double(leakScores.count)
    }

    /// Estimate closure rate (fully enclosed regions)
    private func closureRate(_ image: UIImage, regionCount: Int) -> Double {
        guard regionCount > 0 else { return 1.0 }

        // For simplicity, estimate based on leak potential
        // Lower leak potential = higher closure rate
        let leaks = leakPotential(image)
        return max(0, 1.0 - leaks)
    }

    /// Estimate tap usability (regions large enough for kids to tap)
    private func tapUsability(_ image: UIImage, minTapArea: Int? = nil) -> Double {
        guard let cgImage = image.cgImage else { return 1.0 }

        let width = cgImage.width
        let height = cgImage.height
        let effectiveMinTapArea = minTapArea ?? self.minTapArea

        guard let pixelData = getGrayscalePixels(cgImage) else { return 1.0 }

        // Invert
        var inverted = [UInt8](repeating: 0, count: width * height)
        for i in 0..<(width * height) {
            inverted[i] = pixelData[i] > 200 ? 1 : 0
        }

        var visited = [Bool](repeating: false, count: width * height)
        var totalRegions = 0
        var tappableRegions = 0

        for y in 0..<height {
            for x in 0..<width {
                let idx = y * width + x
                if inverted[idx] == 1 && !visited[idx] {
                    let area = floodFillArea(inverted: &inverted, visited: &visited,
                                             x: x, y: y, width: width, height: height)
                    if area >= 20 {  // Valid region
                        totalRegions += 1
                        if area >= effectiveMinTapArea {
                            tappableRegions += 1
                        }
                    }
                }
            }
        }

        return totalRegions > 0 ? Double(tappableRegions) / Double(totalRegions) : 1.0
    }

    // MARK: - Helpers

    private func getGrayscalePixels(_ cgImage: CGImage) -> [UInt8]? {
        let width = cgImage.width
        let height = cgImage.height

        var pixels = [UInt8](repeating: 0, count: width * height)

        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return nil }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        return pixels
    }

    private func floodFillArea(inverted: inout [UInt8], visited: inout [Bool],
                                x: Int, y: Int, width: Int, height: Int) -> Int {
        var stack = [(x, y)]
        var area = 0

        while !stack.isEmpty {
            let (cx, cy) = stack.removeLast()

            if cx < 0 || cx >= width || cy < 0 || cy >= height { continue }

            let idx = cy * width + cx
            if visited[idx] || inverted[idx] == 0 { continue }

            visited[idx] = true
            area += 1

            // Add 4 neighbors
            stack.append((cx + 1, cy))
            stack.append((cx - 1, cy))
            stack.append((cx, cy + 1))
            stack.append((cx, cy - 1))
        }

        return area
    }
}
