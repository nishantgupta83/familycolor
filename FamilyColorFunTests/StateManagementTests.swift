import XCTest
@testable import FamilyColorFun

final class StateManagementTests: XCTestCase {

    // MARK: - FillEngine Tests

    func testFillEngineInitialization() {
        let image = createTestImage()
        let engine = FillEngine(image: image)

        XCTAssertEqual(engine.progress, 0)
        XCTAssertFalse(engine.canUndo)
        XCTAssertNotNil(engine.currentImage)
    }

    func testFillEngineFillOperation() {
        let image = createTestImage()
        let engine = FillEngine(image: image)

        let point = CGPoint(x: 0.5, y: 0.5)
        engine.fill(at: point, with: .red)

        XCTAssertTrue(engine.canUndo)
    }

    func testFillEngineUndo() {
        let image = createTestImage()
        let engine = FillEngine(image: image)

        engine.fill(at: CGPoint(x: 0.5, y: 0.5), with: .blue)
        XCTAssertTrue(engine.canUndo)

        engine.undo()
        XCTAssertFalse(engine.canUndo)
    }

    func testFillEngineMultipleUndos() {
        let image = createTestImage()
        let engine = FillEngine(image: image)

        // Fill multiple times
        for i in 0..<5 {
            let x = CGFloat(i) * 0.1 + 0.2
            engine.fill(at: CGPoint(x: x, y: 0.5), with: .green)
        }

        // Undo all
        for _ in 0..<5 {
            if engine.canUndo {
                engine.undo()
            }
        }

        XCTAssertFalse(engine.canUndo)
    }

    func testFillEngineClear() {
        let image = createTestImage()
        let engine = FillEngine(image: image)

        engine.fill(at: CGPoint(x: 0.5, y: 0.5), with: .red)
        engine.clear()

        XCTAssertTrue(engine.canUndo) // Can undo the clear
    }

    func testFillEngineUndoStackLimit() {
        let image = createTestImage()
        let engine = FillEngine(image: image)

        // Fill more than max undo steps (10)
        for i in 0..<15 {
            let x = CGFloat(i) * 0.05 + 0.1
            engine.fill(at: CGPoint(x: x, y: 0.5), with: .purple)
        }

        // Should still be able to undo (up to max)
        var undoCount = 0
        while engine.canUndo {
            engine.undo()
            undoCount += 1
        }

        XCTAssertLessThanOrEqual(undoCount, 10)
    }

    // MARK: - DrawingEngine Tests

    func testDrawingEngineInitialization() {
        let engine = DrawingEngine()

        XCTAssertTrue(engine.paths.isEmpty)
        XCTAssertTrue(engine.filledAreas.isEmpty)
        XCTAssertNil(engine.currentPath)
        XCTAssertFalse(engine.canUndo)
        XCTAssertEqual(engine.progress, 0)
    }

    func testDrawingEngineStartPath() {
        let engine = DrawingEngine()

        engine.startPath(at: CGPoint(x: 100, y: 100), color: .red, lineWidth: 10, isEraser: false)

        XCTAssertNotNil(engine.currentPath)
    }

    func testDrawingEngineAddPoint() {
        let engine = DrawingEngine()

        engine.startPath(at: CGPoint(x: 100, y: 100), color: .red, lineWidth: 10, isEraser: false)
        engine.addPoint(CGPoint(x: 150, y: 150))
        engine.addPoint(CGPoint(x: 200, y: 100))

        XCTAssertEqual(engine.currentPath?.points.count, 3)
    }

    func testDrawingEngineEndPath() {
        let engine = DrawingEngine()

        engine.startPath(at: CGPoint(x: 100, y: 100), color: .red, lineWidth: 10, isEraser: false)
        engine.addPoint(CGPoint(x: 150, y: 150))
        engine.endPath()

        XCTAssertNil(engine.currentPath)
        XCTAssertEqual(engine.paths.count, 1)
        XCTAssertTrue(engine.canUndo)
    }

    func testDrawingEngineUndo() {
        let engine = DrawingEngine()

        engine.startPath(at: CGPoint(x: 100, y: 100), color: .red, lineWidth: 10, isEraser: false)
        engine.endPath()
        XCTAssertEqual(engine.paths.count, 1)

        engine.undo()
        XCTAssertEqual(engine.paths.count, 0)
    }

    func testDrawingEngineClear() {
        let engine = DrawingEngine()

        engine.startPath(at: CGPoint(x: 100, y: 100), color: .red, lineWidth: 10, isEraser: false)
        engine.endPath()
        engine.startPath(at: CGPoint(x: 200, y: 200), color: .blue, lineWidth: 10, isEraser: false)
        engine.endPath()

        engine.clear()

        XCTAssertTrue(engine.paths.isEmpty)
        XCTAssertTrue(engine.filledAreas.isEmpty)
    }

    // MARK: - Category Tests

    func testCategoryCount() {
        XCTAssertEqual(Category.all.count, 5)
    }

    func testCategoryNames() {
        let names = Category.all.map { $0.name }
        XCTAssertTrue(names.contains("Animals"))
        XCTAssertTrue(names.contains("Vehicles"))
        XCTAssertTrue(names.contains("Houses"))
        XCTAssertTrue(names.contains("Nature"))
        XCTAssertTrue(names.contains("Ocean"))
    }

    func testCategoryPagesNotEmpty() {
        for category in Category.all {
            XCTAssertFalse(category.pages.isEmpty, "\(category.name) should have pages")
        }
    }

    // MARK: - ColoringPage Tests

    func testAnimalsPageCount() {
        XCTAssertEqual(ColoringPage.animals.count, 3)
    }

    func testVehiclesPageCount() {
        XCTAssertEqual(ColoringPage.vehicles.count, 1)
    }

    func testColoringPageUniqueIds() {
        let allPages = ColoringPage.animals + ColoringPage.vehicles + ColoringPage.houses + ColoringPage.nature + ColoringPage.ocean
        let ids = allPages.map { $0.id }
        let uniqueIds = Set(ids)
        XCTAssertEqual(ids.count, uniqueIds.count, "All page IDs should be unique")
    }

    // MARK: - Helpers

    private func createTestImage() -> UIImage {
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            UIColor.black.setStroke()
            let path = UIBezierPath(rect: CGRect(x: 20, y: 20, width: 60, height: 60))
            path.lineWidth = 2
            path.stroke()
        }
    }
}
