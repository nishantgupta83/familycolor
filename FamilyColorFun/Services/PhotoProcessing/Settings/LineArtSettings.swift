import Foundation

/// Settings for line art extraction
struct LineArtSettings {
    /// Maximum image dimension (controls detail level)
    var maxDimension: Int

    /// Contrast adjustment for contour detection (1.0-3.0)
    var contrastAdjustment: Float

    /// Contrast boost during preprocessing
    var contrastBoost: Float

    /// Blur amount for preprocessing (0 = none, higher = more blur)
    var blurAmount: Float

    /// Engine type to use for extraction
    var engineType: EngineType

    /// Post-processing configuration
    var postProcess: PostProcessConfig

    /// Post-processing configuration (grouped for clarity)
    struct PostProcessConfig {
        /// Kernel size for gap sealing (1-8 pixels)
        var closeKernel: Int

        /// Line thickness after dilation (1-8 pixels)
        var thickness: Int

        /// Minimum area for speckle removal
        var minSpeckleArea: Int

        /// Whether to merge tiny regions (toddler mode)
        var simplifyRegions: Bool

        /// Minimum region area for simplification
        var minRegionArea: Int

        static let `default` = PostProcessConfig(
            closeKernel: 1,
            thickness: 2,
            minSpeckleArea: 30,
            simplifyRegions: false,
            minRegionArea: 500
        )

        static let toddler = PostProcessConfig(
            closeKernel: 8,
            thickness: 6,
            minSpeckleArea: 100,
            simplifyRegions: true,
            minRegionArea: 2000
        )
    }

    static let `default` = LineArtSettings(
        maxDimension: 768,
        contrastAdjustment: 2.0,
        contrastBoost: 1.2,
        blurAmount: 0,
        engineType: .vision,
        postProcess: .default
    )

    // MARK: - Legacy Compatibility

    /// Line thickness (delegates to postProcess)
    var thickness: Int {
        get { postProcess.thickness }
        set { postProcess.thickness = newValue }
    }

    /// Whether to apply large gap closing (delegates to postProcess)
    var closeLargeGaps: Bool {
        get { postProcess.closeKernel > 1 }
        set { postProcess.closeKernel = newValue ? 3 : 1 }
    }

    /// Kernel size for large gap closing (delegates to postProcess)
    var largeGapKernel: Int {
        get { postProcess.closeKernel }
        set { postProcess.closeKernel = newValue }
    }

    /// Minimum region area (delegates to postProcess)
    var minRegionArea: Int {
        get { postProcess.minRegionArea }
        set { postProcess.minRegionArea = newValue }
    }

    /// Whether to simplify regions (delegates to postProcess)
    var simplifyRegions: Bool {
        get { postProcess.simplifyRegions }
        set { postProcess.simplifyRegions = newValue }
    }
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
            return LineArtSettings(
                maxDimension: 256,
                contrastAdjustment: 1.2,
                contrastBoost: 1.1,
                blurAmount: 3.0,
                engineType: .vision,
                postProcess: .toddler
            )
        case .portrait:
            return LineArtSettings(
                maxDimension: 768,
                contrastAdjustment: 2.5,
                contrastBoost: 1.3,
                blurAmount: 0,
                engineType: .hed,  // HED better for portraits
                postProcess: LineArtSettings.PostProcessConfig(
                    closeKernel: 1,
                    thickness: 3,
                    minSpeckleArea: 30,
                    simplifyRegions: false,
                    minRegionArea: 500
                )
            )
        case .landscape:
            return LineArtSettings(
                maxDimension: 512,
                contrastAdjustment: 2.0,
                contrastBoost: 1.2,
                blurAmount: 0,
                engineType: .vision,
                postProcess: .default
            )
        case .object:
            return LineArtSettings(
                maxDimension: 768,
                contrastAdjustment: 2.8,
                contrastBoost: 1.4,
                blurAmount: 0,
                engineType: .vision,
                postProcess: .default
            )
        case .pet:
            return LineArtSettings(
                maxDimension: 512,
                contrastAdjustment: 2.2,
                contrastBoost: 1.3,
                blurAmount: 0,
                engineType: .vision,
                postProcess: LineArtSettings.PostProcessConfig(
                    closeKernel: 4,
                    thickness: 3,
                    minSpeckleArea: 30,
                    simplifyRegions: false,
                    minRegionArea: 500
                )
            )
        case .abstract:
            return LineArtSettings(
                maxDimension: 384,
                contrastAdjustment: 1.5,
                contrastBoost: 1.1,
                blurAmount: 1.0,
                engineType: .vision,
                postProcess: LineArtSettings.PostProcessConfig(
                    closeKernel: 5,
                    thickness: 4,
                    minSpeckleArea: 30,
                    simplifyRegions: false,
                    minRegionArea: 500
                )
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
