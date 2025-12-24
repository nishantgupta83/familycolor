import UIKit
import Combine

/// Coordinates the full photo-to-coloring workflow
/// Manages state, caching, and engine switching
final class LineArtOrchestrator: ObservableObject {

    // MARK: - Public Properties

    /// Current processing state
    var state: ProcessingState { stateManager.state }

    /// Current run ID
    var currentRunID: UUID { stateManager.currentRunID }

    // MARK: - Private Properties

    private let stateManager = ProcessingStateManager()
    private let registry = EngineRegistry.shared
    private let preprocessor = ImagePreprocessor()
    private let postProcessor = LineArtPostProcessor()
    private let validator = FillabilityValidator()

    /// Current processing context (nil when idle)
    private var context: ProcessingContext?

    // MARK: - Public API

    /// Process a photo into line art
    /// - Parameters:
    ///   - photo: The photo to process
    ///   - settings: Processing settings
    /// - Returns: The processed line art result
    func process(
        photo: UIImage,
        settings: LineArtSettings
    ) async throws -> LineArtResult {
        // Start new run
        let runID = stateManager.newRun()

        // Create context
        context = ProcessingContext(
            runID: runID,
            originalPhoto: photo,
            settings: settings,
            requestedEngine: settings.engineType
        )

        // Resolve engine (with fallback)
        let resolvedEngine = registry.resolveEngine(requested: settings.engineType)
        context?.resolvedEngine = resolvedEngine

        // Transition to loading
        guard stateManager.transition(to: .loadingPhoto, forRun: runID) else {
            throw ProcessingError.unknown("Failed to start processing")
        }

        do {
            // Create task for cancellation support
            let task = Task<LineArtResult, Error> {
                try await performProcessing(runID: runID, settings: settings, resolvedEngine: resolvedEngine)
            }
            context?.currentTask = task

            return try await task.value
        } catch {
            stateManager.transition(to: .failed(error: error as? ProcessingError ?? .unknown(error.localizedDescription)), forRun: runID)
            throw error
        }
    }

    /// Reprocess with a different engine (reuses preprocessed image)
    /// - Parameter engineType: The new engine to use
    /// - Returns: The new result
    func reprocess(with engineType: EngineType) async throws -> LineArtResult {
        guard let context = context else {
            throw ProcessingError.unknown("No active context for reprocessing")
        }

        let runID = context.runID
        let resolvedEngine = registry.resolveEngine(requested: engineType)
        context.resolvedEngine = resolvedEngine

        // Transition to extracting (skip preprocessing if cached)
        guard stateManager.transition(to: .extractingLines(resolvedEngine: resolvedEngine, progress: 0), forRun: runID) else {
            throw ProcessingError.unknown("Cannot reprocess in current state")
        }

        do {
            let task = Task<LineArtResult, Error> {
                try await performExtraction(
                    runID: runID,
                    context: context,
                    settings: context.settingsSnapshot,
                    resolvedEngine: resolvedEngine
                )
            }
            context.currentTask = task

            return try await task.value
        } catch {
            stateManager.transition(to: .failed(error: error as? ProcessingError ?? .unknown(error.localizedDescription)), forRun: runID)
            throw error
        }
    }

    /// Cancel current processing
    func cancel() {
        context?.cancel()
        let runID = stateManager.currentRunID
        stateManager.transition(to: .cancelling, forRun: runID)
        stateManager.transition(to: .cancelled, forRun: runID)
    }

    /// Reset to idle state
    func reset() {
        context = nil
        stateManager.reset()
    }

    // MARK: - Private Methods

    private func performProcessing(
        runID: UUID,
        settings: LineArtSettings,
        resolvedEngine: EngineType
    ) async throws -> LineArtResult {
        guard let context = context else {
            throw ProcessingError.unknown("Context not available")
        }

        // Preprocess
        stateManager.transition(to: .preprocessing(progress: 0), forRun: runID)
        try context.checkCancellation()

        let preprocessed = try await performPreprocessing(
            context: context,
            settings: settings,
            engine: resolvedEngine
        )

        stateManager.transition(to: .preprocessing(progress: 1.0), forRun: runID)
        try context.checkCancellation()

        // Cache preprocessed image
        context.cachePreprocessed(preprocessed, for: resolvedEngine)

        // Extract and complete
        return try await performExtraction(
            runID: runID,
            context: context,
            settings: settings,
            resolvedEngine: resolvedEngine
        )
    }

    private func performPreprocessing(
        context: ProcessingContext,
        settings: LineArtSettings,
        engine: EngineType
    ) async throws -> CGImage {
        // Check cache first
        if let cached = context.getPreprocessed(for: engine) {
            return cached
        }

        // Get engine to determine preferred size
        let engineInstance = registry.engine(for: engine)
        let targetSize = engineInstance?.preferredInputSize ?? settings.maxDimension

        // Preprocess photo
        let preprocessed = preprocessor.preprocess(
            context.originalPhoto,
            settings: settings,
            targetSize: targetSize
        )

        guard let cgImage = preprocessed.cgImage else {
            throw ProcessingError.preprocessingFailed("Failed to get CGImage from preprocessed")
        }

        return cgImage
    }

    private func performExtraction(
        runID: UUID,
        context: ProcessingContext,
        settings: LineArtSettings,
        resolvedEngine: EngineType
    ) async throws -> LineArtResult {
        // Transition to extracting
        stateManager.transition(to: .extractingLines(resolvedEngine: resolvedEngine, progress: 0), forRun: runID)
        try context.checkCancellation()

        // Get preprocessed image (from cache or process)
        let preprocessed: CGImage
        if let cached = context.getPreprocessed(for: resolvedEngine) {
            preprocessed = cached
        } else {
            preprocessed = try await performPreprocessing(context: context, settings: settings, engine: resolvedEngine)
            context.cachePreprocessed(preprocessed, for: resolvedEngine)
        }

        // Get engine
        guard let engine = registry.engine(for: resolvedEngine) else {
            throw ProcessingError.engineNotAvailable(resolvedEngine)
        }

        // Extract edges
        let edgeMap = try await engine.extractEdges(from: preprocessed, settings: settings)
        context.lastEdgeMap = edgeMap

        stateManager.transition(to: .extractingLines(resolvedEngine: resolvedEngine, progress: 1.0), forRun: runID)
        try context.checkCancellation()

        // Post-process
        stateManager.transition(to: .postProcessing, forRun: runID)
        try context.checkCancellation()

        let intermediate = postProcessor.process(edgeMap: edgeMap, settings: settings)
        context.lastIntermediate = intermediate

        try context.checkCancellation()

        // Validate
        stateManager.transition(to: .validating, forRun: runID)
        try context.checkCancellation()

        let fillability = validator.evaluate(intermediate.lineImage)

        // Complete
        let result = LineArtResult(
            lineArt: intermediate.lineImage,
            fillability: fillability,
            intermediate: intermediate,
            edgeMap: edgeMap,
            runID: runID
        )

        stateManager.transition(to: .complete(result: result), forRun: runID)

        return result
    }
}

// MARK: - ImagePreprocessor Extension

extension ImagePreprocessor {
    /// Preprocess photo with target size
    func preprocess(_ photo: UIImage, settings: LineArtSettings, targetSize: Int) -> UIImage {
        // Create modified settings with target size
        var modifiedSettings = settings
        modifiedSettings.maxDimension = targetSize
        return preprocess(photo, settings: modifiedSettings)
    }
}
