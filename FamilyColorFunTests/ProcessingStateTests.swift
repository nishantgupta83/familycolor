import XCTest
@testable import FamilyColorFun

/// Tests for ProcessingStateManager and EngineRegistry
final class ProcessingStateTests: XCTestCase {

    // MARK: - ProcessingStateManager Tests

    func testInitialState() {
        let manager = ProcessingStateManager()

        XCTAssertEqual(manager.state, .idle)
        XCTAssertTrue(manager.history.isEmpty)
        XCTAssertNotNil(manager.currentRunID)
    }

    func testNewRunResetsState() {
        let manager = ProcessingStateManager()
        let originalRunID = manager.currentRunID

        let newRunID = manager.newRun()

        XCTAssertNotEqual(originalRunID, newRunID)
        XCTAssertEqual(manager.currentRunID, newRunID)
        XCTAssertEqual(manager.state, .idle)
        XCTAssertTrue(manager.history.isEmpty)
    }

    func testValidTransitionFromIdle() {
        let manager = ProcessingStateManager()
        let runID = manager.currentRunID

        XCTAssertTrue(manager.canTransition(to: .loadingPhoto))

        let success = manager.transition(to: .loadingPhoto, forRun: runID)

        XCTAssertTrue(success)
        XCTAssertEqual(manager.state.phase, .loadingPhoto)
        XCTAssertEqual(manager.history.count, 1)
        XCTAssertEqual(manager.history.first, .idle)
    }

    func testInvalidTransitionFromIdle() {
        let manager = ProcessingStateManager()
        let runID = manager.currentRunID

        // Cannot go directly from idle to extractingLines
        XCTAssertFalse(manager.canTransition(to: .extractingLines))

        let success = manager.transition(to: .extractingLines(resolvedEngine: .vision, progress: 0), forRun: runID)

        XCTAssertFalse(success)
        XCTAssertEqual(manager.state.phase, .idle)
    }

    func testFullProcessingPath() {
        let manager = ProcessingStateManager()
        let runID = manager.newRun()

        // idle -> loadingPhoto
        XCTAssertTrue(manager.transition(to: .loadingPhoto, forRun: runID))
        XCTAssertEqual(manager.state.phase, .loadingPhoto)

        // loadingPhoto -> preprocessing
        XCTAssertTrue(manager.transition(to: .preprocessing(progress: 0), forRun: runID))
        XCTAssertEqual(manager.state.phase, .preprocessing)

        // preprocessing -> extractingLines
        XCTAssertTrue(manager.transition(to: .extractingLines(resolvedEngine: .vision, progress: 0), forRun: runID))
        XCTAssertEqual(manager.state.phase, .extractingLines)

        // extractingLines -> postProcessing
        XCTAssertTrue(manager.transition(to: .postProcessing, forRun: runID))
        XCTAssertEqual(manager.state.phase, .postProcessing)

        // postProcessing -> validating
        XCTAssertTrue(manager.transition(to: .validating, forRun: runID))
        XCTAssertEqual(manager.state.phase, .validating)

        // validating -> complete
        let mockResult = createMockResult()
        XCTAssertTrue(manager.transition(to: .complete(result: mockResult), forRun: runID))
        XCTAssertEqual(manager.state.phase, .complete)

        // History should have all previous phases
        XCTAssertEqual(manager.history.count, 6)
    }

    func testStaleRunIDRejected() {
        let manager = ProcessingStateManager()
        let oldRunID = manager.currentRunID

        // Start a new run
        _ = manager.newRun()

        // Try to transition with old run ID
        let success = manager.transition(to: .loadingPhoto, forRun: oldRunID)

        XCTAssertFalse(success, "Stale run ID should be rejected")
        XCTAssertEqual(manager.state.phase, .idle)
    }

    func testCancellationPath() {
        let manager = ProcessingStateManager()
        let runID = manager.newRun()

        // Start processing
        XCTAssertTrue(manager.transition(to: .loadingPhoto, forRun: runID))
        XCTAssertTrue(manager.transition(to: .preprocessing(progress: 0.5), forRun: runID))

        // Cancel
        XCTAssertTrue(manager.transition(to: .cancelling, forRun: runID))
        XCTAssertEqual(manager.state.phase, .cancelling)

        XCTAssertTrue(manager.transition(to: .cancelled, forRun: runID))
        XCTAssertEqual(manager.state.phase, .cancelled)

        // Can return to idle from cancelled
        XCTAssertTrue(manager.transition(to: .idle, forRun: runID))
        XCTAssertEqual(manager.state.phase, .idle)
    }

    func testFailurePath() {
        let manager = ProcessingStateManager()
        let runID = manager.newRun()

        // Start processing
        XCTAssertTrue(manager.transition(to: .loadingPhoto, forRun: runID))

        // Fail
        XCTAssertTrue(manager.transition(to: .failed(error: .unknown("Test error")), forRun: runID))
        XCTAssertEqual(manager.state.phase, .failed)

        // Can return to idle from failed
        XCTAssertTrue(manager.transition(to: .idle, forRun: runID))
        XCTAssertEqual(manager.state.phase, .idle)
    }

    func testReprocessPath() {
        let manager = ProcessingStateManager()
        let runID = manager.newRun()

        // Complete a run
        XCTAssertTrue(manager.transition(to: .loadingPhoto, forRun: runID))
        XCTAssertTrue(manager.transition(to: .preprocessing(progress: 0), forRun: runID))
        XCTAssertTrue(manager.transition(to: .extractingLines(resolvedEngine: .vision, progress: 0), forRun: runID))
        XCTAssertTrue(manager.transition(to: .postProcessing, forRun: runID))
        XCTAssertTrue(manager.transition(to: .validating, forRun: runID))
        XCTAssertTrue(manager.transition(to: .complete(result: createMockResult()), forRun: runID))

        // Reprocess: complete -> extractingLines
        XCTAssertTrue(manager.canTransition(to: .extractingLines))
        XCTAssertTrue(manager.transition(to: .extractingLines(resolvedEngine: .hed, progress: 0), forRun: runID))
        XCTAssertEqual(manager.state.phase, .extractingLines)
    }

    func testProcessingStateProperties() {
        // Test isProcessing
        XCTAssertFalse(ProcessingState.idle.isProcessing)
        XCTAssertTrue(ProcessingState.loadingPhoto.isProcessing)
        XCTAssertTrue(ProcessingState.preprocessing(progress: 0.5).isProcessing)
        XCTAssertTrue(ProcessingState.extractingLines(resolvedEngine: .vision, progress: 0.5).isProcessing)
        XCTAssertTrue(ProcessingState.postProcessing.isProcessing)
        XCTAssertTrue(ProcessingState.validating.isProcessing)
        XCTAssertFalse(ProcessingState.complete(result: createMockResult()).isProcessing)
        XCTAssertFalse(ProcessingState.failed(error: .cancelled).isProcessing)

        // Test progress
        XCTAssertNil(ProcessingState.idle.progress)
        XCTAssertEqual(ProcessingState.preprocessing(progress: 0.5).progress, 0.5)
        XCTAssertEqual(ProcessingState.extractingLines(resolvedEngine: .hed, progress: 0.75).progress, 0.75)
    }

    func testReset() {
        let manager = ProcessingStateManager()
        let runID = manager.newRun()

        // Do some transitions
        XCTAssertTrue(manager.transition(to: .loadingPhoto, forRun: runID))
        XCTAssertTrue(manager.transition(to: .preprocessing(progress: 0.5), forRun: runID))

        // Reset
        manager.reset()

        XCTAssertEqual(manager.state, .idle)
        XCTAssertTrue(manager.history.isEmpty)
    }

    // MARK: - EngineRegistry Tests

    func testEngineRegistrySingleton() {
        let instance1 = EngineRegistry.shared
        let instance2 = EngineRegistry.shared

        XCTAssertTrue(instance1 === instance2)
    }

    func testVisionEngineAlwaysAvailable() {
        let registry = EngineRegistry.shared

        XCTAssertTrue(registry.isAvailable(.vision))
    }

    func testAvailableEnginesContainsVision() {
        let registry = EngineRegistry.shared
        let available = registry.availableEngines()

        XCTAssertTrue(available.contains(.vision))
    }

    func testResolveEngineWithVision() {
        let registry = EngineRegistry.shared

        let resolved = registry.resolveEngine(requested: .vision)

        XCTAssertEqual(resolved, .vision)
    }

    func testResolveEngineWithUnavailableHED() {
        let registry = EngineRegistry.shared

        // If HED is not available, should fallback to Vision
        if !registry.isAvailable(.hed) {
            let resolved = registry.resolveEngine(requested: .hed)
            XCTAssertEqual(resolved, .vision, "Should fallback to Vision when HED unavailable")
        }
    }

    func testEngineForVision() {
        let registry = EngineRegistry.shared

        let engine = registry.engine(for: .vision)

        XCTAssertNotNil(engine)
        XCTAssertEqual(engine?.engineName, "VisionContours")
    }

    func testEngineTypeEnumCases() {
        let allCases = EngineType.allCases

        XCTAssertEqual(allCases.count, 2)
        XCTAssertTrue(allCases.contains(.vision))
        XCTAssertTrue(allCases.contains(.hed))
    }

    func testEngineTypeCodable() throws {
        let original = EngineType.vision

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(EngineType.self, from: data)

        XCTAssertEqual(decoded, original)
    }

    func testEngineTypeHashable() {
        var set: Set<EngineType> = []

        set.insert(.vision)
        set.insert(.hed)
        set.insert(.vision) // Duplicate

        XCTAssertEqual(set.count, 2)
    }

    // MARK: - ProcessingPhase Tests

    func testProcessingPhaseAllCases() {
        let allCases = ProcessingPhase.allCases

        XCTAssertEqual(allCases.count, 11)
        XCTAssertTrue(allCases.contains(.idle))
        XCTAssertTrue(allCases.contains(.loadingPhoto))
        XCTAssertTrue(allCases.contains(.preprocessing))
        XCTAssertTrue(allCases.contains(.extractingLines))
        XCTAssertTrue(allCases.contains(.postProcessing))
        XCTAssertTrue(allCases.contains(.validating))
        XCTAssertTrue(allCases.contains(.analyzing))
        XCTAssertTrue(allCases.contains(.complete))
        XCTAssertTrue(allCases.contains(.failed))
        XCTAssertTrue(allCases.contains(.cancelling))
        XCTAssertTrue(allCases.contains(.cancelled))
    }

    func testProcessingPhaseHashable() {
        var dict: [ProcessingPhase: String] = [:]

        dict[.idle] = "Idle"
        dict[.loadingPhoto] = "Loading"

        XCTAssertEqual(dict[.idle], "Idle")
        XCTAssertEqual(dict[.loadingPhoto], "Loading")
    }

    // MARK: - ProcessingError Tests

    func testProcessingErrorLocalizedDescription() {
        XCTAssertTrue(ProcessingError.cancelled.localizedDescription.contains("cancelled"))
        XCTAssertTrue(ProcessingError.photoLoadFailed("test").localizedDescription.contains("test"))
        XCTAssertTrue(ProcessingError.engineNotAvailable(.hed).localizedDescription.contains("hed"))
    }

    func testProcessingErrorEquatable() {
        XCTAssertEqual(ProcessingError.cancelled, ProcessingError.cancelled)
        XCTAssertEqual(ProcessingError.unknown("a"), ProcessingError.unknown("a"))
        XCTAssertNotEqual(ProcessingError.unknown("a"), ProcessingError.unknown("b"))
    }

    // MARK: - Helper Methods

    private func createMockResult() -> LineArtResult {
        let mockImage = UIImage()
        let mockIntermediate = LineArtIntermediate(
            lineImage: mockImage,
            lineThickness: 2,
            regionEstimate: 10,
            postProcessingApplied: []
        )
        let mockEdgeMap = EdgeMap(
            data: createMockCGImage(),
            isBinary: true,
            engineMeta: EngineMeta(
                engineName: "Test",
                suggestedThreshold: 0.5,
                edgeDensity: 0.1,
                processingTimeMs: 100,
                originalScale: 1.0
            )
        )
        let mockFillability = FillabilityResult(
            score: 0.8,
            regionCount: 10,
            closureRate: 0.9,
            leakPotential: 0.1,
            tapUsability: 0.85,
            suggestions: []
        )

        return LineArtResult(
            lineArt: mockImage,
            fillability: mockFillability,
            intermediate: mockIntermediate,
            edgeMap: mockEdgeMap,
            runID: UUID()
        )
    }

    private func createMockCGImage() -> CGImage {
        let size = CGSize(width: 10, height: 10)
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let context = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: Int(size.width),
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        )!
        context.setFillColor(gray: 1.0, alpha: 1.0)
        context.fill(CGRect(origin: .zero, size: size))
        return context.makeImage()!
    }
}
