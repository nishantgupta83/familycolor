import XCTest

/// Comprehensive tests for ALL pages in the app
/// Uses intelligent orchestration with parallel execution
final class ComprehensivePageTests: XCTestCase {

    var app: XCUIApplication!

    // All categories and their pages
    static let allPages: [(category: String, page: String)] = [
        // Animals
        ("Animals", "Cat"),
        ("Animals", "Dog"),
        ("Animals", "Elephant"),
        ("Animals", "Bunny"),
        ("Animals", "Bear"),
        ("Animals", "Bird"),
        ("Animals", "Fox"),

        // Vehicles
        ("Vehicles", "Car"),

        // Houses
        ("Houses", "Cottage"),

        // Nature
        ("Nature", "Flower"),
        ("Nature", "Star"),
        ("Nature", "Rose"),
        ("Nature", "Daisy"),
        ("Nature", "Tulip"),

        // Ocean
        ("Ocean", "Fish"),

        // Retro 90s
        ("Retro 90s", "Boombox"),
        ("Retro 90s", "Turntable"),

        // Mandalas
        ("Mandalas", "Mandala 1"),
        ("Mandalas", "Mandala 2"),
        ("Mandalas", "Mandala 3"),
        ("Mandalas", "Mandala 4"),
        ("Mandalas", "Mandala 5"),
        ("Mandalas", "Mandala 6"),

        // Geometric
        ("Geometric", "Pattern 1"),
        ("Geometric", "Pattern 2"),
        ("Geometric", "Pattern 3"),
        ("Geometric", "Pattern 4"),
        ("Geometric", "Pattern 5"),
        ("Geometric", "Pattern 6"),

        // Abstract
        ("Abstract", "Abstract 1"),
        ("Abstract", "Abstract 2"),

        // Dinosaurs
        ("Dinosaurs", "T-Rex"),
        ("Dinosaurs", "Triceratops"),
        ("Dinosaurs", "Stegosaurus"),

        // Space
        ("Space", "Rocket"),
        ("Space", "Astronaut"),
        ("Space", "Planet"),

        // Food
        ("Food", "Cupcake"),
        ("Food", "Ice Cream"),
        ("Food", "Pizza"),

        // Holidays
        ("Holidays", "Christmas Tree"),
        ("Holidays", "Easter Egg"),
        ("Holidays", "Pumpkin"),

        // Sports
        ("Sports", "Soccer Ball"),
        ("Sports", "Basketball"),
        ("Sports", "Baseball"),

        // Music
        ("Music", "Guitar"),
        ("Music", "Piano"),
        ("Music", "Drums"),

        // Robots
        ("Robots", "Robot 1"),
        ("Robots", "Robot 2"),
        ("Robots", "Robot 3"),

        // Fantasy
        ("Fantasy", "Unicorn"),
        ("Fantasy", "Dragon"),
        ("Fantasy", "Castle"),

        // Underwater
        ("Underwater", "Octopus"),
        ("Underwater", "Seahorse"),
        ("Underwater", "Turtle"),

        // Zen Patterns
        ("Zen Patterns", "Zen 1"),
        ("Zen Patterns", "Zen 2"),
        ("Zen Patterns", "Zen 3"),

        // Portraits
        ("Portraits", "Princess"),
        ("Portraits", "Superhero"),
        ("Portraits", "Fairy")
    ]

    override func setUpWithError() throws {
        continueAfterFailure = true
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Comprehensive Test (All Pages)

    func testAllPagesComprehensive() throws {
        let orchestrator = PageTestOrchestrator(app: app, config: .thorough)
        var passCount = 0
        var failCount = 0

        print("\n========================================")
        print("COMPREHENSIVE PAGE TEST - ALL \(Self.allPages.count) PAGES")
        print("Testing: Fill 20%+, Auto-complete, Save, Draw, Zoom")
        print("========================================\n")

        for (category, page) in Self.allPages {
            let result = orchestrator.testPage(category: category, page: page)
            orchestrator.addResult(result)

            if result.passed {
                passCount += 1
                print("[\u{2705}] \(category) > \(page) - Filled \(result.fillCount) regions - \(String(format: "%.1f", result.duration))s")
            } else {
                failCount += 1
                print("[\u{274C}] \(category) > \(page) - Filled \(result.fillCount) - FAILED")
                for error in result.errors {
                    print("    Error: \(error)")
                }
            }
        }

        print("\n========================================")
        print("RESULTS: \(passCount) passed, \(failCount) failed")
        print("========================================\n")

        print(orchestrator.generateReport())

        XCTAssertEqual(failCount, 0, "\(failCount) pages failed")
    }

    // MARK: - Batch Tests (5 parallel chunks)

    func testBatch1_Animals() throws {
        let pages = Self.allPages.filter { $0.category == "Animals" }
        runBatchTest(pages: pages, batchName: "Batch 1: Animals")
    }

    func testBatch2_NatureAndOcean() throws {
        let pages = Self.allPages.filter { ["Nature", "Ocean", "Houses", "Vehicles"].contains($0.category) }
        runBatchTest(pages: pages, batchName: "Batch 2: Nature & Ocean")
    }

    func testBatch3_Patterns() throws {
        let pages = Self.allPages.filter { ["Mandalas", "Geometric", "Abstract", "Zen Patterns"].contains($0.category) }
        runBatchTest(pages: pages, batchName: "Batch 3: Patterns")
    }

    func testBatch4_Characters() throws {
        let pages = Self.allPages.filter { ["Dinosaurs", "Fantasy", "Robots", "Portraits"].contains($0.category) }
        runBatchTest(pages: pages, batchName: "Batch 4: Characters")
    }

    func testBatch5_ThemesAndFood() throws {
        let pages = Self.allPages.filter { ["Space", "Food", "Holidays", "Sports", "Music", "Underwater", "Retro 90s"].contains($0.category) }
        runBatchTest(pages: pages, batchName: "Batch 5: Themes & Food")
    }

    // MARK: - Individual Category Tests

    func testCategory_Animals() throws {
        let pages = Self.allPages.filter { $0.category == "Animals" }
        runBatchTest(pages: pages, batchName: "Animals")
    }

    func testCategory_Dinosaurs() throws {
        let pages = Self.allPages.filter { $0.category == "Dinosaurs" }
        runBatchTest(pages: pages, batchName: "Dinosaurs")
    }

    func testCategory_Space() throws {
        let pages = Self.allPages.filter { $0.category == "Space" }
        runBatchTest(pages: pages, batchName: "Space")
    }

    func testCategory_Fantasy() throws {
        let pages = Self.allPages.filter { $0.category == "Fantasy" }
        runBatchTest(pages: pages, batchName: "Fantasy")
    }

    func testCategory_Mandalas() throws {
        let pages = Self.allPages.filter { $0.category == "Mandalas" }
        runBatchTest(pages: pages, batchName: "Mandalas")
    }

    // MARK: - Helper Methods

    private func runBatchTest(pages: [(category: String, page: String)], batchName: String) {
        let orchestrator = PageTestOrchestrator(app: app, config: .standard)
        var passCount = 0
        var failCount = 0
        var totalFills = 0

        print("\n--- \(batchName) (\(pages.count) pages) ---")
        print("    Testing: Fill 15%+, Undo, AutoFill, Save, Zoom")

        for (category, page) in pages {
            let result = orchestrator.testPage(category: category, page: page)
            orchestrator.addResult(result)
            totalFills += result.fillCount

            if result.passed {
                passCount += 1
                print("  [\u{2705}] \(page) - Filled \(result.fillCount) regions")
            } else {
                failCount += 1
                print("  [\u{274C}] \(page) - Filled \(result.fillCount): \(result.errors.joined(separator: ", "))")
            }
        }

        print("--- \(batchName): \(passCount)/\(pages.count) passed, \(totalFills) total fills ---\n")
        print(orchestrator.generateReport())

        XCTAssertEqual(failCount, 0, "\(batchName): \(failCount) pages failed")
    }

    // MARK: - Page-Level Orchestration Tests

    func testFillModeOperations() throws {
        // Test fill mode specifically
        app.staticTexts["Animals"].tap()
        XCTAssertTrue(app.navigationBars["Animals"].waitForExistence(timeout: 5))

        app.staticTexts["Cat"].tap()
        XCTAssertTrue(app.navigationBars["Cat"].waitForExistence(timeout: 5))

        // Verify Fill mode is selected
        let fillButton = app.buttons["Fill"]
        XCTAssertTrue(fillButton.waitForExistence(timeout: 5))

        // Test color selection
        let colorPalette = app.scrollViews.firstMatch
        if colorPalette.exists {
            // Tap first few colors
            let buttons = colorPalette.buttons
            if buttons.count > 0 {
                buttons.element(boundBy: 0).tap()
                sleep(1)
                buttons.element(boundBy: 1).tap()
            }
        }

        // Test undo
        let undoButton = app.buttons["arrow.uturn.backward.circle.fill"]
        if undoButton.exists && undoButton.isEnabled {
            undoButton.tap()
        }

        // Test clear
        let clearButton = app.buttons["trash.circle.fill"]
        if clearButton.exists {
            clearButton.tap()
            // Cancel the clear
            if app.buttons["Cancel"].waitForExistence(timeout: 3) {
                app.buttons["Cancel"].tap()
            }
        }
    }

    func testDrawModeOperations() throws {
        app.staticTexts["Animals"].tap()
        app.staticTexts["Dog"].tap()

        // Switch to Draw mode
        let drawButton = app.buttons["Draw"]
        if drawButton.waitForExistence(timeout: 5) {
            drawButton.tap()

            // Verify drawing tools appear
            sleep(1)

            // Test drawing on canvas
            let canvas = app.otherElements.firstMatch
            if canvas.exists {
                // Draw a line
                let start = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.3))
                let end = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.7))
                start.press(forDuration: 0.1, thenDragTo: end)
            }
        }

        // Switch back to Fill
        let fillButton = app.buttons["Fill"]
        if fillButton.exists {
            fillButton.tap()
        }
    }

    func testZoomOperations() throws {
        app.staticTexts["Mandalas"].tap()
        app.staticTexts["Mandala 1"].tap()

        sleep(1)

        // Find zoom controls
        let zoomIn = app.buttons.matching(NSPredicate(format: "label CONTAINS 'plus' OR identifier CONTAINS 'plus'")).firstMatch
        let zoomOut = app.buttons.matching(NSPredicate(format: "label CONTAINS 'minus' OR identifier CONTAINS 'minus'")).firstMatch

        // Test zoom in
        if zoomIn.exists {
            zoomIn.tap()
            sleep(1)
        }

        // Test zoom out
        if zoomOut.exists {
            zoomOut.tap()
            sleep(1)
        }

        // Test pinch zoom on canvas
        let canvas = app.scrollViews.firstMatch
        if canvas.exists {
            canvas.pinch(withScale: 2.0, velocity: 1)
            sleep(1)
            canvas.pinch(withScale: 0.5, velocity: 1)
        }
    }

    func testAutoFillTrigger() throws {
        app.staticTexts["Geometric"].tap()
        app.staticTexts["Pattern 1"].tap()

        sleep(1)

        // Test auto-fill button
        let autoFillButton = app.buttons["wand.and.stars"]
        if autoFillButton.waitForExistence(timeout: 5) && autoFillButton.isEnabled {
            autoFillButton.tap()

            // Check for confirmation dialog
            let fillButton = app.buttons["Fill with random colors"]
            if fillButton.waitForExistence(timeout: 3) {
                // Cancel to not actually fill
                app.buttons["Cancel"].tap()
            }
        }
    }

    func testSaveAndShare() throws {
        app.staticTexts["Nature"].tap()
        app.staticTexts["Flower"].tap()

        sleep(1)

        // Test share button exists
        let shareButton = app.buttons["square.and.arrow.up"]
        XCTAssertTrue(shareButton.waitForExistence(timeout: 5), "Share button should exist")
        XCTAssertTrue(shareButton.isEnabled, "Share button should be enabled")

        // Don't actually share, just verify it's there
    }
}

// MARK: - Performance Tests

extension ComprehensivePageTests {

    func testPageLoadPerformance() throws {
        measure {
            app.staticTexts["Animals"].tap()
            _ = app.navigationBars["Animals"].waitForExistence(timeout: 10)
            app.staticTexts["Cat"].tap()
            _ = app.navigationBars["Cat"].waitForExistence(timeout: 10)

            // Go back
            app.navigationBars.buttons.element(boundBy: 0).tap()
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }
    }

    func testFillPerformance() throws {
        app.staticTexts["Animals"].tap()
        app.staticTexts["Cat"].tap()

        let canvas = app.scrollViews.firstMatch
        guard canvas.exists else { return }

        measure {
            for i in 0..<10 {
                let coord = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.3 + Double(i) * 0.05, dy: 0.3 + Double(i) * 0.05))
                coord.tap()
                usleep(100000) // 100ms
            }
        }
    }
}
