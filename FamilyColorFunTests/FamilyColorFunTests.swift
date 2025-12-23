import XCTest
import SwiftUI
@testable import FamilyColorFun

final class FamilyColorFunTests: XCTestCase {

    // MARK: - Category Tests

    func testCategoryInitialization() {
        let category = Category(name: "Test", icon: "star.fill", color: .red, pages: [])

        XCTAssertEqual(category.name, "Test")
        XCTAssertEqual(category.icon, "star.fill")
        XCTAssertEqual(category.color, .red)
        XCTAssertTrue(category.pages.isEmpty)
        XCTAssertNotNil(category.id)
    }

    func testCategoryAllContainsFiveCategories() {
        XCTAssertEqual(Category.all.count, 5)
    }

    func testCategoryAllHasExpectedNames() {
        let expectedNames = ["Animals", "Vehicles", "Houses", "Nature", "Ocean"]
        let categoryNames = Category.all.map { $0.name }

        XCTAssertEqual(categoryNames, expectedNames)
    }

    func testCategoryAllHasPagesForEachCategory() {
        for category in Category.all {
            XCTAssertFalse(category.pages.isEmpty, "\(category.name) should have pages")
        }
    }

    // MARK: - ColoringPage Tests

    func testColoringPageInitialization() {
        let page = ColoringPage(name: "Test Page", imageName: "test_image")

        XCTAssertEqual(page.name, "Test Page")
        XCTAssertEqual(page.imageName, "test_image")
        XCTAssertNotNil(page.id)
    }

    func testAnimalsPageCount() {
        XCTAssertEqual(ColoringPage.animals.count, 3)
    }

    func testVehiclesPageCount() {
        XCTAssertEqual(ColoringPage.vehicles.count, 1)
    }

    func testHousesPageCount() {
        XCTAssertEqual(ColoringPage.houses.count, 1)
    }

    func testNaturePageCount() {
        XCTAssertEqual(ColoringPage.nature.count, 5)
    }

    func testOceanPageCount() {
        XCTAssertEqual(ColoringPage.ocean.count, 1)
    }

    func testColoringPageUniqueIDs() {
        let pages = ColoringPage.animals
        let ids = pages.map { $0.id }
        let uniqueIds = Set(ids)

        XCTAssertEqual(ids.count, uniqueIds.count, "All page IDs should be unique")
    }

    // MARK: - Artwork Tests

    func testArtworkInitialization() {
        let pageId = UUID()
        let artwork = Artwork(
            pageId: pageId,
            pageName: "Cat",
            categoryName: "Animals",
            imagePath: "test.png",
            progress: 0.5
        )

        XCTAssertEqual(artwork.pageId, pageId)
        XCTAssertEqual(artwork.pageName, "Cat")
        XCTAssertEqual(artwork.categoryName, "Animals")
        XCTAssertEqual(artwork.imagePath, "test.png")
        XCTAssertEqual(artwork.progress, 0.5)
        XCTAssertNotNil(artwork.id)
        XCTAssertNotNil(artwork.savedDate)
    }

    func testArtworkDefaultProgress() {
        let artwork = Artwork(
            pageId: UUID(),
            pageName: "Test",
            categoryName: "Test",
            imagePath: "test.png"
        )

        XCTAssertEqual(artwork.progress, 0.0)
    }

    func testArtworkCodable() throws {
        let original = Artwork(
            pageId: UUID(),
            pageName: "Dog",
            categoryName: "Animals",
            imagePath: "dog.png",
            progress: 0.75
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Artwork.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.pageId, original.pageId)
        XCTAssertEqual(decoded.pageName, original.pageName)
        XCTAssertEqual(decoded.categoryName, original.categoryName)
        XCTAssertEqual(decoded.imagePath, original.imagePath)
        XCTAssertEqual(decoded.progress, original.progress)
    }

    // MARK: - DrawingPath Tests

    func testDrawingPathInitialization() {
        let point1 = CGPoint(x: 10, y: 20)
        let point2 = CGPoint(x: 30, y: 40)
        let path = DrawingPath(points: [point1, point2], color: .red, lineWidth: 5, isEraser: false)

        XCTAssertEqual(path.points.count, 2)
        XCTAssertEqual(path.color, .red)
        XCTAssertEqual(path.lineWidth, 5)
        XCTAssertFalse(path.isEraser)
        XCTAssertNotNil(path.id)
    }

    func testDrawingPathDefaultValues() {
        let path = DrawingPath()

        XCTAssertTrue(path.points.isEmpty)
        XCTAssertEqual(path.color, .black)
        XCTAssertEqual(path.lineWidth, 8)
        XCTAssertFalse(path.isEraser)
    }

    func testDrawingPathEraserMode() {
        let path = DrawingPath(points: [], color: .white, lineWidth: 10, isEraser: true)

        XCTAssertTrue(path.isEraser)
        XCTAssertEqual(path.color, .white)
    }

    // MARK: - FilledArea Tests

    func testFilledAreaInitialization() {
        let point = CGPoint(x: 100, y: 200)
        let area = FilledArea(point: point, color: .blue)

        XCTAssertEqual(area.point, point)
        XCTAssertEqual(area.color, .blue)
        XCTAssertNotNil(area.id)
    }

    // MARK: - DrawingEngine Tests

    func testDrawingEngineInitialization() {
        let engine = DrawingEngine()

        XCTAssertTrue(engine.paths.isEmpty)
        XCTAssertTrue(engine.filledAreas.isEmpty)
        XCTAssertNil(engine.currentPath)
        XCTAssertEqual(engine.progress, 0.0)
        XCTAssertFalse(engine.canUndo)
    }

    func testDrawingEngineStartPath() {
        let engine = DrawingEngine()
        let point = CGPoint(x: 50, y: 50)

        engine.startPath(at: point, color: .red, lineWidth: 5, isEraser: false)

        XCTAssertNotNil(engine.currentPath)
        XCTAssertEqual(engine.currentPath?.points.count, 1)
        XCTAssertEqual(engine.currentPath?.points.first, point)
        XCTAssertEqual(engine.currentPath?.color, .red)
        XCTAssertEqual(engine.currentPath?.lineWidth, 5)
    }

    func testDrawingEngineAddPoint() {
        let engine = DrawingEngine()
        let startPoint = CGPoint(x: 10, y: 10)
        let secondPoint = CGPoint(x: 20, y: 20)

        engine.startPath(at: startPoint, color: .blue, lineWidth: 3, isEraser: false)
        engine.addPoint(secondPoint)

        XCTAssertEqual(engine.currentPath?.points.count, 2)
        XCTAssertEqual(engine.currentPath?.points.last, secondPoint)
    }

    func testDrawingEngineEndPath() {
        let engine = DrawingEngine()
        let point1 = CGPoint(x: 10, y: 10)
        let point2 = CGPoint(x: 20, y: 20)

        engine.startPath(at: point1, color: .green, lineWidth: 4, isEraser: false)
        engine.addPoint(point2)
        engine.endPath()

        XCTAssertNil(engine.currentPath)
        XCTAssertEqual(engine.paths.count, 1)
        XCTAssertEqual(engine.paths.first?.points.count, 2)
    }

    func testDrawingEngineEndPathWithSinglePoint() {
        let engine = DrawingEngine()
        let point = CGPoint(x: 10, y: 10)

        engine.startPath(at: point, color: .red, lineWidth: 5, isEraser: false)
        engine.endPath()

        XCTAssertNil(engine.currentPath)
        XCTAssertEqual(engine.paths.count, 0, "Paths with only one point should not be saved")
    }

    func testDrawingEngineFill() {
        let engine = DrawingEngine()
        let point = CGPoint(x: 100, y: 100)

        engine.fill(at: point, with: .yellow)

        XCTAssertEqual(engine.filledAreas.count, 1)
        XCTAssertEqual(engine.filledAreas.first?.point, point)
        XCTAssertEqual(engine.filledAreas.first?.color, .yellow)
    }

    func testDrawingEngineUndo() {
        let engine = DrawingEngine()
        let point1 = CGPoint(x: 10, y: 10)
        let point2 = CGPoint(x: 20, y: 20)

        engine.startPath(at: point1, color: .red, lineWidth: 5, isEraser: false)
        engine.addPoint(point2)
        engine.endPath()

        XCTAssertEqual(engine.paths.count, 1)
        XCTAssertTrue(engine.canUndo)

        engine.undo()

        XCTAssertEqual(engine.paths.count, 0)
    }

    func testDrawingEngineUndoFilledAreas() {
        let engine = DrawingEngine()
        let fillPoint = CGPoint(x: 50, y: 50)

        engine.fill(at: fillPoint, with: .blue)

        XCTAssertEqual(engine.filledAreas.count, 1)

        engine.undo()

        XCTAssertEqual(engine.filledAreas.count, 0)
    }

    func testDrawingEngineUndoOrder() {
        let engine = DrawingEngine()
        let pathPoint1 = CGPoint(x: 10, y: 10)
        let pathPoint2 = CGPoint(x: 20, y: 20)
        let fillPoint = CGPoint(x: 50, y: 50)

        // Add path first
        engine.startPath(at: pathPoint1, color: .red, lineWidth: 5, isEraser: false)
        engine.addPoint(pathPoint2)
        engine.endPath()

        // Then add fill
        engine.fill(at: fillPoint, with: .blue)

        XCTAssertEqual(engine.paths.count, 1)
        XCTAssertEqual(engine.filledAreas.count, 1)

        // First undo should remove the path (paths are removed first)
        engine.undo()
        XCTAssertEqual(engine.paths.count, 0)
        XCTAssertEqual(engine.filledAreas.count, 1)

        // Second undo should remove the filled area
        engine.undo()
        XCTAssertEqual(engine.filledAreas.count, 0)
    }

    func testDrawingEngineCanUndoWithPaths() {
        let engine = DrawingEngine()
        let point1 = CGPoint(x: 10, y: 10)
        let point2 = CGPoint(x: 20, y: 20)

        XCTAssertFalse(engine.canUndo)

        engine.startPath(at: point1, color: .red, lineWidth: 5, isEraser: false)
        engine.addPoint(point2)
        engine.endPath()

        XCTAssertTrue(engine.canUndo)
    }

    func testDrawingEngineCanUndoWithFilledAreas() {
        let engine = DrawingEngine()
        let point = CGPoint(x: 50, y: 50)

        XCTAssertFalse(engine.canUndo)

        engine.fill(at: point, with: .blue)

        XCTAssertTrue(engine.canUndo)
    }

    func testDrawingEngineProgressWithPaths() {
        let engine = DrawingEngine()

        XCTAssertEqual(engine.progress, 0.0)

        // Add 5 paths
        for i in 0..<5 {
            let point1 = CGPoint(x: CGFloat(i * 10), y: 0)
            let point2 = CGPoint(x: CGFloat(i * 10), y: 10)
            engine.startPath(at: point1, color: .red, lineWidth: 5, isEraser: false)
            engine.addPoint(point2)
            engine.endPath()
        }

        XCTAssertGreaterThan(engine.progress, 0.0)
        XCTAssertLessThanOrEqual(engine.progress, 1.0)
    }

    func testDrawingEngineProgressWithFills() {
        let engine = DrawingEngine()

        XCTAssertEqual(engine.progress, 0.0)

        // Add 5 fills
        for i in 0..<5 {
            engine.fill(at: CGPoint(x: CGFloat(i * 20), y: 50), with: .blue)
        }

        XCTAssertGreaterThan(engine.progress, 0.0)
        XCTAssertLessThanOrEqual(engine.progress, 1.0)
    }

    func testDrawingEngineProgressMaxValue() {
        let engine = DrawingEngine()

        // Add maximum paths (20 paths = 0.5 progress)
        for i in 0..<20 {
            let point1 = CGPoint(x: CGFloat(i), y: 0)
            let point2 = CGPoint(x: CGFloat(i), y: 10)
            engine.startPath(at: point1, color: .red, lineWidth: 5, isEraser: false)
            engine.addPoint(point2)
            engine.endPath()
        }

        // Add maximum fills (10 fills = 0.5 progress)
        for i in 0..<10 {
            engine.fill(at: CGPoint(x: CGFloat(i * 20), y: 50), with: .blue)
        }

        XCTAssertEqual(engine.progress, 1.0, accuracy: 0.01)
    }

    func testDrawingEngineClear() {
        let engine = DrawingEngine()
        let point1 = CGPoint(x: 10, y: 10)
        let point2 = CGPoint(x: 20, y: 20)

        engine.startPath(at: point1, color: .red, lineWidth: 5, isEraser: false)
        engine.addPoint(point2)
        engine.endPath()
        engine.fill(at: CGPoint(x: 50, y: 50), with: .blue)

        XCTAssertEqual(engine.paths.count, 1)
        XCTAssertEqual(engine.filledAreas.count, 1)
        XCTAssertGreaterThan(engine.progress, 0.0)

        engine.clear()

        XCTAssertTrue(engine.paths.isEmpty)
        XCTAssertTrue(engine.filledAreas.isEmpty)
        XCTAssertEqual(engine.progress, 0.0)
        XCTAssertFalse(engine.canUndo)
    }

    // MARK: - Color Extension Tests

    func testKidColorsCount() {
        XCTAssertEqual(Color.kidColors.count, 12)
    }

    func testColorNamesCount() {
        XCTAssertEqual(Color.colorNames.count, 12)
    }

    func testKidColorsAndNamesMatch() {
        XCTAssertEqual(Color.kidColors.count, Color.colorNames.count)
    }

    func testColorNamesAreExpected() {
        let expectedNames = ["Cherry", "Tangerine", "Sunshine", "Lime", "Grass", "Ocean", "Sky", "Grape", "Plum", "Bubblegum", "Chocolate", "Cloud"]

        XCTAssertEqual(Color.colorNames, expectedNames)
    }

    func testColorHexInitialization6Digits() {
        let color = Color(hex: "FF0000")
        let uiColor = UIColor(color)

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        XCTAssertEqual(red, 1.0, accuracy: 0.01)
        XCTAssertEqual(green, 0.0, accuracy: 0.01)
        XCTAssertEqual(blue, 0.0, accuracy: 0.01)
        XCTAssertEqual(alpha, 1.0, accuracy: 0.01)
    }

    func testColorHexInitialization3Digits() {
        let color = Color(hex: "F00")
        let uiColor = UIColor(color)

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        XCTAssertEqual(red, 1.0, accuracy: 0.01)
        XCTAssertEqual(green, 0.0, accuracy: 0.01)
        XCTAssertEqual(blue, 0.0, accuracy: 0.01)
        XCTAssertEqual(alpha, 1.0, accuracy: 0.01)
    }

    func testColorHexInitializationWithHash() {
        let color = Color(hex: "#00FF00")
        let uiColor = UIColor(color)

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        XCTAssertEqual(red, 0.0, accuracy: 0.01)
        XCTAssertEqual(green, 1.0, accuracy: 0.01)
        XCTAssertEqual(blue, 0.0, accuracy: 0.01)
        XCTAssertEqual(alpha, 1.0, accuracy: 0.01)
    }

    func testColorToUIColor() {
        let color = Color.red
        let uiColor = color.toUIColor()

        XCTAssertNotNil(uiColor)
        XCTAssertTrue(uiColor is UIColor)
    }

    // MARK: - SoundManager Tests

    func testSoundManagerSingleton() {
        let instance1 = SoundManager.shared
        let instance2 = SoundManager.shared

        XCTAssertTrue(instance1 === instance2)
    }

    func testSoundManagerMuteToggle() {
        let soundManager = SoundManager.shared
        let initialState = soundManager.isMuted

        soundManager.toggleMute()
        XCTAssertEqual(soundManager.isMuted, !initialState)

        soundManager.toggleMute()
        XCTAssertEqual(soundManager.isMuted, initialState)
    }

    func testSoundManagerMutePersistence() {
        let soundManager = SoundManager.shared
        soundManager.isMuted = true

        XCTAssertTrue(UserDefaults.standard.bool(forKey: "sound_muted"))

        soundManager.isMuted = false
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "sound_muted"))
    }

    // MARK: - StorageService Tests

    func testStorageServiceSingleton() {
        let instance1 = StorageService.shared
        let instance2 = StorageService.shared

        XCTAssertTrue(instance1 === instance2)
    }

    func testStorageServiceInitialState() {
        let storageService = StorageService.shared

        XCTAssertNotNil(storageService.artworks)
    }

    func testStorageServiceSaveAndLoadImage() {
        let storageService = StorageService.shared
        let testImage = createTestImage()
        let testPage = ColoringPage(name: "Test", imageName: "test")
        let testCategory = Category(name: "Test", icon: "star.fill", color: .red, pages: [testPage])

        let savedArtwork = storageService.saveArtwork(image: testImage, page: testPage, category: testCategory, progress: 0.5)

        XCTAssertNotNil(savedArtwork)
        XCTAssertEqual(savedArtwork?.pageName, "Test")
        XCTAssertEqual(savedArtwork?.categoryName, "Test")
        XCTAssertEqual(savedArtwork?.progress, 0.5)

        if let artwork = savedArtwork {
            let loadedImage = storageService.loadImage(from: artwork.imagePath)
            XCTAssertNotNil(loadedImage)

            // Cleanup
            storageService.deleteArtwork(artwork)
        }
    }

    func testStorageServiceDeleteArtwork() {
        let storageService = StorageService.shared
        let testImage = createTestImage()
        let testPage = ColoringPage(name: "Test", imageName: "test")
        let testCategory = Category(name: "Test", icon: "star.fill", color: .red, pages: [testPage])

        let initialCount = storageService.artworks.count

        guard let artwork = storageService.saveArtwork(image: testImage, page: testPage, category: testCategory, progress: 0.3) else {
            XCTFail("Failed to save artwork")
            return
        }

        XCTAssertEqual(storageService.artworks.count, initialCount + 1)

        storageService.deleteArtwork(artwork)

        XCTAssertEqual(storageService.artworks.count, initialCount)

        let loadedImage = storageService.loadImage(from: artwork.imagePath)
        XCTAssertNil(loadedImage, "Image file should be deleted")
    }

    // MARK: - Helper Methods

    private func createTestImage() -> UIImage {
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContext(size)
        defer { UIGraphicsEndImageContext() }

        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.red.cgColor)
        context?.fill(CGRect(origin: .zero, size: size))

        return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
    }
}
