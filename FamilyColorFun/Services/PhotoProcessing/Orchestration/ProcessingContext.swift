import CoreGraphics
import UIKit

/// Context for a photo processing run
/// Caches preprocessed images per-engine for fast engine switching
final class ProcessingContext {
    // MARK: - Immutable Properties

    /// Unique identifier for this processing run
    let runID: UUID

    /// Original photo to process
    let originalPhoto: UIImage

    /// Settings snapshot at start of processing
    let settingsSnapshot: LineArtSettings

    /// Engine requested by user (for UI display)
    let requestedEngine: EngineType

    // MARK: - Mutable State

    /// Actual engine used after fallback resolution (for debugging)
    var resolvedEngine: EngineType?

    /// Per-engine preprocessed image cache
    /// Vision and HED may need different input sizes
    var preprocessedByEngine: [EngineType: CGImage] = [:]

    /// Last edge map for quick re-preview
    var lastEdgeMap: EdgeMap?

    /// Last intermediate result
    var lastIntermediate: LineArtIntermediate?

    /// Reference to current processing task (for cancellation)
    /// Note: Task is a struct - we store it directly and clear on completion
    var currentTask: Task<LineArtResult, Error>?

    // MARK: - Initialization

    init(
        runID: UUID,
        originalPhoto: UIImage,
        settings: LineArtSettings,
        requestedEngine: EngineType
    ) {
        self.runID = runID
        self.originalPhoto = originalPhoto
        self.settingsSnapshot = settings
        self.requestedEngine = requestedEngine
    }

    // MARK: - Computed Properties

    /// Whether the current task has been cancelled
    var isCancelled: Bool {
        currentTask?.isCancelled ?? false
    }

    /// Whether we have a cached preprocessed image for the given engine
    func hasPreprocessed(for engine: EngineType) -> Bool {
        preprocessedByEngine[engine] != nil
    }

    /// Get cached preprocessed image for an engine
    func getPreprocessed(for engine: EngineType) -> CGImage? {
        preprocessedByEngine[engine]
    }

    /// Cache a preprocessed image for an engine
    func cachePreprocessed(_ image: CGImage, for engine: EngineType) {
        preprocessedByEngine[engine] = image
    }

    // MARK: - Cancellation

    /// Request cancellation of current processing
    func cancel() {
        currentTask?.cancel()
    }

    /// Check for cancellation and throw if cancelled
    func checkCancellation() throws {
        if isCancelled {
            throw ProcessingError.cancelled
        }
    }
}

// MARK: - Debugging

extension ProcessingContext: CustomDebugStringConvertible {
    var debugDescription: String {
        """
        ProcessingContext(\(runID.uuidString.prefix(8))):
          requested: \(requestedEngine.rawValue)
          resolved: \(resolvedEngine?.rawValue ?? "nil")
          cached engines: \(preprocessedByEngine.keys.map(\.rawValue).joined(separator: ", "))
          hasEdgeMap: \(lastEdgeMap != nil)
          isCancelled: \(isCancelled)
        """
    }
}
