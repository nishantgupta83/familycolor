import Foundation

/// Settings for line art extraction
struct LineArtSettings {
    /// Maximum image dimension (controls detail level)
    var maxDimension: Int

    /// Contrast adjustment for contour detection (1.0-3.0)
    var contrastAdjustment: Float

    /// Line thickness after dilation (1-5 pixels)
    var thickness: Int

    /// Whether to apply large gap closing
    var closeLargeGaps: Bool

    /// Kernel size for large gap closing (3-6 pixels)
    var largeGapKernel: Int

    /// Contrast boost during preprocessing
    var contrastBoost: Float

    static let `default` = LineArtSettings(
        maxDimension: 768,
        contrastAdjustment: 2.0,
        thickness: 2,
        closeLargeGaps: false,
        largeGapKernel: 3,
        contrastBoost: 1.2
    )
}

/// Preset configurations for different photo types
enum LineArtPreset: String, CaseIterable {
    case portrait
    case landscape
    case object
    case pet
    case abstract

    var settings: LineArtSettings {
        switch self {
        case .portrait:
            return LineArtSettings(
                maxDimension: 768,
                contrastAdjustment: 2.5,
                thickness: 3,
                closeLargeGaps: false,
                largeGapKernel: 3,
                contrastBoost: 1.3
            )
        case .landscape:
            return LineArtSettings(
                maxDimension: 512,
                contrastAdjustment: 2.0,
                thickness: 2,
                closeLargeGaps: false,
                largeGapKernel: 3,
                contrastBoost: 1.2
            )
        case .object:
            return LineArtSettings(
                maxDimension: 768,
                contrastAdjustment: 2.8,
                thickness: 2,
                closeLargeGaps: false,
                largeGapKernel: 3,
                contrastBoost: 1.4
            )
        case .pet:
            return LineArtSettings(
                maxDimension: 512,
                contrastAdjustment: 2.2,
                thickness: 3,
                closeLargeGaps: true,
                largeGapKernel: 4,
                contrastBoost: 1.3
            )
        case .abstract:
            return LineArtSettings(
                maxDimension: 384,
                contrastAdjustment: 1.5,
                thickness: 4,
                closeLargeGaps: true,
                largeGapKernel: 5,
                contrastBoost: 1.1
            )
        }
    }

    var displayName: String {
        switch self {
        case .portrait: return "Portrait"
        case .landscape: return "Landscape"
        case .object: return "Object"
        case .pet: return "Pet"
        case .abstract: return "Abstract"
        }
    }

    var icon: String {
        switch self {
        case .portrait: return "person.fill"
        case .landscape: return "mountain.2.fill"
        case .object: return "cube.fill"
        case .pet: return "pawprint.fill"
        case .abstract: return "scribble.variable"
        }
    }
}
