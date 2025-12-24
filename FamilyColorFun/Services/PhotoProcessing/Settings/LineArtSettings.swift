import Foundation

/// Settings for line art extraction
struct LineArtSettings {
    /// Maximum image dimension (controls detail level)
    var maxDimension: Int

    /// Contrast adjustment for contour detection (1.0-3.0)
    var contrastAdjustment: Float

    /// Line thickness after dilation (1-8 pixels)
    var thickness: Int

    /// Whether to apply large gap closing
    var closeLargeGaps: Bool

    /// Kernel size for large gap closing (3-8 pixels)
    var largeGapKernel: Int

    /// Contrast boost during preprocessing
    var contrastBoost: Float

    /// Blur amount for preprocessing (0 = none, higher = more blur)
    var blurAmount: Float

    /// Minimum region area in pixels (for toddler mode)
    var minRegionArea: Int

    /// Whether to merge tiny regions into neighbors
    var simplifyRegions: Bool

    static let `default` = LineArtSettings(
        maxDimension: 768,
        contrastAdjustment: 2.0,
        thickness: 2,
        closeLargeGaps: false,
        largeGapKernel: 3,
        contrastBoost: 1.2,
        blurAmount: 0,
        minRegionArea: 500,
        simplifyRegions: false
    )
}

/// Preset configurations for different photo types
enum LineArtPreset: String, CaseIterable {
    case toddler    // For ages 2-5: simple, bold, forgiving
    case portrait
    case landscape
    case object
    case pet
    case abstract

    var settings: LineArtSettings {
        switch self {
        case .toddler:
            // Optimized for toddlers: simple, bold lines, large tap targets
            // Key: low resolution (256) = fewer contours detected
            // High thickness (6) = bold, easy-to-see lines
            // Aggressive gap closing (kernel 8) = 100% closure rate
            // Large minRegionArea (2000) = only big, easy-to-tap regions
            return LineArtSettings(
                maxDimension: 256,
                contrastAdjustment: 1.2,
                thickness: 6,
                closeLargeGaps: true,
                largeGapKernel: 8,
                contrastBoost: 1.1,
                blurAmount: 3.0,
                minRegionArea: 2000,
                simplifyRegions: true
            )
        case .portrait:
            return LineArtSettings(
                maxDimension: 768,
                contrastAdjustment: 2.5,
                thickness: 3,
                closeLargeGaps: false,
                largeGapKernel: 3,
                contrastBoost: 1.3,
                blurAmount: 0,
                minRegionArea: 500,
                simplifyRegions: false
            )
        case .landscape:
            return LineArtSettings(
                maxDimension: 512,
                contrastAdjustment: 2.0,
                thickness: 2,
                closeLargeGaps: false,
                largeGapKernel: 3,
                contrastBoost: 1.2,
                blurAmount: 0,
                minRegionArea: 500,
                simplifyRegions: false
            )
        case .object:
            return LineArtSettings(
                maxDimension: 768,
                contrastAdjustment: 2.8,
                thickness: 2,
                closeLargeGaps: false,
                largeGapKernel: 3,
                contrastBoost: 1.4,
                blurAmount: 0,
                minRegionArea: 500,
                simplifyRegions: false
            )
        case .pet:
            return LineArtSettings(
                maxDimension: 512,
                contrastAdjustment: 2.2,
                thickness: 3,
                closeLargeGaps: true,
                largeGapKernel: 4,
                contrastBoost: 1.3,
                blurAmount: 0,
                minRegionArea: 500,
                simplifyRegions: false
            )
        case .abstract:
            return LineArtSettings(
                maxDimension: 384,
                contrastAdjustment: 1.5,
                thickness: 4,
                closeLargeGaps: true,
                largeGapKernel: 5,
                contrastBoost: 1.1,
                blurAmount: 1.0,
                minRegionArea: 500,
                simplifyRegions: false
            )
        }
    }

    var displayName: String {
        switch self {
        case .toddler: return "For Toddlers"
        case .portrait: return "Portrait"
        case .landscape: return "Landscape"
        case .object: return "Object"
        case .pet: return "Pet"
        case .abstract: return "Abstract"
        }
    }

    var icon: String {
        switch self {
        case .toddler: return "figure.and.child.holdinghands"
        case .portrait: return "person.fill"
        case .landscape: return "mountain.2.fill"
        case .object: return "cube.fill"
        case .pet: return "pawprint.fill"
        case .abstract: return "scribble.variable"
        }
    }

    /// Description for UI tooltips
    var description: String {
        switch self {
        case .toddler: return "Simple, bold lines with large areas - perfect for ages 2-5"
        case .portrait: return "Best for selfies and face photos"
        case .landscape: return "Scenic views with clear edges"
        case .object: return "Simple objects on plain backgrounds"
        case .pet: return "Close-up photos of pets"
        case .abstract: return "Simplified artistic style"
        }
    }
}
