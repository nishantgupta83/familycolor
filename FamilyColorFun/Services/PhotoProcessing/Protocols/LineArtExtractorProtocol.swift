import CoreGraphics

/// Protocol for line art extraction engines (new architecture)
/// Engines extract edges ONLY - no post-processing
/// Returns EdgeMap instead of UIImage for proper separation of concerns
protocol LineArtExtractorProtocol {
    /// Extract edges from a preprocessed image
    /// - Parameters:
    ///   - preprocessedImage: Image that has already been resized/enhanced
    ///   - settings: Settings for extraction (contrast, etc.)
    /// - Returns: EdgeMap containing edge data and metadata
    func extractEdges(
        from preprocessedImage: CGImage,
        settings: LineArtSettings
    ) async throws -> EdgeMap

    /// Engine name for analytics/logging
    var engineName: String { get }

    /// Whether the engine is available on this device
    var isAvailable: Bool { get }

    /// Preferred input size for this engine
    /// Used by preprocessor to create engine-specific cached variants
    var preferredInputSize: Int { get }
}

extension LineArtExtractorProtocol {
    /// Default preferred input size (can be overridden)
    var preferredInputSize: Int { 512 }
}
