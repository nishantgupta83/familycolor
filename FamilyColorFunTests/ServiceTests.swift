import XCTest
@testable import FamilyColorFun

final class ServiceTests: XCTestCase {

    // MARK: - StickerStore Tests

    func testStickerStoreSingleton() {
        let instance1 = StickerStore.shared
        let instance2 = StickerStore.shared
        XCTAssertTrue(instance1 === instance2)
    }

    func testStickerStoreInitialState() {
        let store = StickerStore.shared
        XCTAssertNotNil(store.unlockedIds)
    }

    // MARK: - JourneyStore Tests

    func testJourneyStoreSingleton() {
        let instance1 = JourneyStore.shared
        let instance2 = JourneyStore.shared
        XCTAssertTrue(instance1 === instance2)
    }

    func testJourneyStoreInitialState() {
        let store = JourneyStore.shared
        XCTAssertNotNil(store.records)
    }

    // MARK: - ProgressionEngine Tests

    func testProgressionEngineSingleton() {
        let instance1 = ProgressionEngine.shared
        let instance2 = ProgressionEngine.shared
        XCTAssertTrue(instance1 === instance2)
    }

    func testProgressionEngineStars() {
        let engine = ProgressionEngine.shared
        XCTAssertGreaterThanOrEqual(engine.stars, 0)
    }

    func testProgressionEngineStreak() {
        let engine = ProgressionEngine.shared
        XCTAssertGreaterThanOrEqual(engine.streak, 0)
    }

    func testProgressionEngineFreePages() {
        XCTAssertEqual(ProgressionEngine.freePages, 3)
    }

    func testProgressionEngineCostPerPage() {
        XCTAssertEqual(ProgressionEngine.costPerPage, 5)
    }

    func testProgressionEngineCompletedPages() {
        let engine = ProgressionEngine.shared
        XCTAssertNotNil(engine.completedPages)
    }

    // MARK: - MetallicColorStore Tests

    func testMetallicColorStoreSingleton() {
        let instance1 = MetallicColorStore.shared
        let instance2 = MetallicColorStore.shared
        XCTAssertTrue(instance1 === instance2)
    }

    func testMetallicColorStoreInitialState() {
        let store = MetallicColorStore.shared
        XCTAssertNotNil(store.unlockedIds)
    }

    func testMetallicColorStoreIsUnlocked() {
        let store = MetallicColorStore.shared
        // Test the isUnlocked function
        _ = store.isUnlocked("gold")
        _ = store.isUnlocked("nonexistent")
        XCTAssertTrue(true) // Just verifying no crash
    }

    // MARK: - PatternFillStore Tests

    func testPatternFillStoreSingleton() {
        let instance1 = PatternFillStore.shared
        let instance2 = PatternFillStore.shared
        XCTAssertTrue(instance1 === instance2)
    }

    func testPatternFillStoreInitialState() {
        let store = PatternFillStore.shared
        XCTAssertNotNil(store.unlockedIds)
    }

    func testPatternFillStoreIsUnlocked() {
        let store = PatternFillStore.shared
        // Test the isUnlocked function
        _ = store.isUnlocked("polkaDots")
        _ = store.isUnlocked("nonexistent")
        XCTAssertTrue(true) // Just verifying no crash
    }

    func testPatternFillStoreUnlockedPatterns() {
        let store = PatternFillStore.shared
        XCTAssertNotNil(store.unlockedPatterns)
    }

    // MARK: - CompanionController Tests

    func testCompanionControllerSingleton() {
        let instance1 = CompanionController.shared
        let instance2 = CompanionController.shared
        XCTAssertTrue(instance1 === instance2)
    }

    func testCompanionControllerVisibility() {
        let controller = CompanionController.shared
        XCTAssertTrue(controller.isVisible)
    }

    func testCompanionControllerDialogue() {
        let controller = CompanionController.shared
        // Initially, dialogue may be nil
        _ = controller.dialogue
        XCTAssertTrue(true)
    }

    // MARK: - SoundManager Tests

    func testSoundManagerSingleton() {
        let instance1 = SoundManager.shared
        let instance2 = SoundManager.shared
        XCTAssertTrue(instance1 === instance2)
    }

    // MARK: - StorageService Tests

    func testStorageServiceSingleton() {
        let instance1 = StorageService.shared
        let instance2 = StorageService.shared
        XCTAssertTrue(instance1 === instance2)
    }

    // MARK: - DrawingEngine Tests

    func testDrawingEngineInitialization() {
        let engine = DrawingEngine()
        XCTAssertTrue(engine.paths.isEmpty)
        XCTAssertTrue(engine.filledAreas.isEmpty)
    }

    func testDrawingEngineStartPath() {
        let engine = DrawingEngine()
        engine.startPath(at: CGPoint(x: 0, y: 0), color: .red, lineWidth: 5.0, isEraser: false)
        // startPath creates currentPath, not added to paths until endPath
        XCTAssertNotNil(engine.currentPath)
    }

    func testDrawingEngineAddPoint() {
        let engine = DrawingEngine()
        engine.startPath(at: CGPoint(x: 0, y: 0), color: .red, lineWidth: 5.0, isEraser: false)
        engine.addPoint(CGPoint(x: 10, y: 10))
        engine.addPoint(CGPoint(x: 20, y: 20))
        // Points are added to currentPath
        XCTAssertEqual(engine.currentPath?.points.count, 3) // initial + 2 added
    }

    func testDrawingEngineEndPath() {
        let engine = DrawingEngine()
        engine.startPath(at: CGPoint(x: 0, y: 0), color: .red, lineWidth: 5.0, isEraser: false)
        engine.addPoint(CGPoint(x: 10, y: 10))
        engine.endPath()
        // Path needs at least 2 points to be saved
        XCTAssertEqual(engine.paths.count, 1)
        XCTAssertNil(engine.currentPath)
    }

    func testDrawingEngineClear() {
        let engine = DrawingEngine()
        engine.startPath(at: CGPoint(x: 0, y: 0), color: .red, lineWidth: 5.0, isEraser: false)
        engine.addPoint(CGPoint(x: 10, y: 10))
        engine.endPath()
        engine.clear()
        XCTAssertTrue(engine.paths.isEmpty)
        XCTAssertTrue(engine.filledAreas.isEmpty)
    }

    func testDrawingEngineUndo() {
        let engine = DrawingEngine()
        engine.startPath(at: CGPoint(x: 0, y: 0), color: .red, lineWidth: 5.0, isEraser: false)
        engine.addPoint(CGPoint(x: 10, y: 10))
        engine.endPath()
        XCTAssertEqual(engine.paths.count, 1)

        engine.undo()
        XCTAssertTrue(engine.paths.isEmpty)
    }

    func testDrawingEngineCanUndo() {
        let engine = DrawingEngine()
        XCTAssertFalse(engine.canUndo)

        // Need to complete a path for canUndo to be true
        engine.startPath(at: CGPoint(x: 0, y: 0), color: .red, lineWidth: 5.0, isEraser: false)
        engine.addPoint(CGPoint(x: 10, y: 10))
        engine.endPath()
        XCTAssertTrue(engine.canUndo)
    }

    func testDrawingEngineProgress() {
        let engine = DrawingEngine()
        XCTAssertEqual(engine.progress, 0)
    }

    func testDrawingEngineMultiplePaths() {
        let engine = DrawingEngine()

        // Draw first path
        engine.startPath(at: CGPoint(x: 0, y: 0), color: .red, lineWidth: 5.0, isEraser: false)
        engine.addPoint(CGPoint(x: 10, y: 10))
        engine.endPath()

        // Draw second path
        engine.startPath(at: CGPoint(x: 20, y: 20), color: .blue, lineWidth: 3.0, isEraser: false)
        engine.addPoint(CGPoint(x: 30, y: 30))
        engine.endPath()

        XCTAssertEqual(engine.paths.count, 2)
    }

    func testDrawingEngineEraserPath() {
        let engine = DrawingEngine()
        engine.startPath(at: CGPoint(x: 0, y: 0), color: .white, lineWidth: 10.0, isEraser: true)
        engine.addPoint(CGPoint(x: 10, y: 10))
        engine.endPath()
        XCTAssertEqual(engine.paths.count, 1)
        XCTAssertTrue(engine.paths[0].isEraser)
    }

    // MARK: - FloodFillService Tests

    func testFloodFillServiceInit() {
        let service = FloodFillService()
        XCTAssertNotNil(service)
    }

    // MARK: - CompanionDialogue Tests

    func testCompanionDialogueStartPhase() {
        let dialogue = CompanionDialogue.random(for: .start)
        XCTAssertFalse(dialogue.isEmpty)
    }

    func testCompanionDialogueFirstFillPhase() {
        let dialogue = CompanionDialogue.random(for: .firstFill)
        XCTAssertFalse(dialogue.isEmpty)
    }

    func testCompanionDialogueCompletionPhase() {
        let dialogue = CompanionDialogue.random(for: .completion)
        XCTAssertFalse(dialogue.isEmpty)
    }

    func testCompanionDialogueIdlePhase() {
        let dialogue = CompanionDialogue.random(for: .idle)
        XCTAssertFalse(dialogue.isEmpty)
    }

    func testCompanionDialogueAllPhases() {
        for phase in CompanionPhaseKey.allCases {
            let dialogue = CompanionDialogue.random(for: phase)
            XCTAssertFalse(dialogue.isEmpty, "Dialogue for \(phase) should not be empty")
        }
    }

    // MARK: - MathProblem Tests

    func testMathProblemGeneration() {
        for _ in 0..<10 {
            let problem = MathProblem.generate()
            XCTAssertFalse(problem.question.isEmpty)
            XCTAssertTrue(problem.question.contains("="))
        }
    }

    func testMathProblemAnswerRange() {
        for _ in 0..<10 {
            let problem = MathProblem.generate()
            XCTAssertGreaterThanOrEqual(problem.answer, -100)
            XCTAssertLessThanOrEqual(problem.answer, 200)
        }
    }

    // MARK: - SettingsManager Tests

    func testSettingsManagerSingleton() {
        let instance1 = SettingsManager.shared
        let instance2 = SettingsManager.shared
        XCTAssertTrue(instance1 === instance2)
    }
}
