import XCTest

// MARK: - Persona-Based UI Tests
/// Tests the app using different user persona agents
/// Each persona simulates realistic user behavior
final class PersonaUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Young Child Tests (Ages 3-5)

    func testYoungChildScenario() throws {
        let agent = YoungChildAgent(app: app)
        let result = try agent.runTestScenario()

        print(result.summary)
        XCTAssertTrue(result.passed, result.failureReason ?? "Young child scenario failed")
    }

    func testYoungChildRandomTapping() throws {
        let agent = YoungChildAgent(app: app)

        // Just random tapping test
        agent.navigateToHome()
        agent.selectCategory("Animals")

        let pages = app.scrollViews.buttons
        if pages.count > 0 {
            pages.element(boundBy: 0).tap()
        }

        let canvas = app.images.firstMatch
        XCTAssertTrue(canvas.waitForExistence(timeout: 3), "Canvas should load")

        // Young child taps randomly 15 times
        for _ in 0..<15 {
            agent.selectRandomColor()
            agent.tapRandomLocation(in: canvas)
        }

        // App should not crash
        XCTAssertTrue(app.exists, "App should remain stable after random tapping")
    }

    // MARK: - Older Child Tests (Ages 6-9)

    func testOlderChildScenario() throws {
        let agent = OlderChildAgent(app: app)
        let result = try agent.runTestScenario()

        print(result.summary)
        XCTAssertTrue(result.passed, result.failureReason ?? "Older child scenario failed")
    }

    func testOlderChildCompletePageFlow() throws {
        let agent = OlderChildAgent(app: app)

        agent.navigateToHome()
        agent.selectCategory("Dinosaurs")

        // Select first page
        let pages = app.scrollViews.buttons
        XCTAssertTrue(pages.count > 0, "Should have pages to select")
        pages.element(boundBy: 0).tap()

        let canvas = app.images.firstMatch
        XCTAssertTrue(canvas.waitForExistence(timeout: 3), "Canvas should load")

        // Methodical coloring
        for i in 0..<8 {
            agent.selectColor(at: i)
            agent.fillRegion(at: CGPoint(x: 0.2 + CGFloat(i) * 0.08, y: 0.5))
        }

        // Test undo
        agent.tapUndo()
        XCTAssertTrue(canvas.exists, "Canvas should still exist after undo")

        // Continue coloring
        agent.selectColor(at: 2)
        agent.fillRegion(at: CGPoint(x: 0.6, y: 0.6))
    }

    // MARK: - Parent Tests

    func testParentScenario() throws {
        let agent = ParentAgent(app: app)
        let result = try agent.runTestScenario()

        print(result.summary)
        XCTAssertTrue(result.passed, result.failureReason ?? "Parent scenario failed")
    }

    func testParentSettingsAccess() throws {
        let agent = ParentAgent(app: app)

        agent.navigateToHome()

        // Open settings
        let settingsButton = app.buttons["gearshape"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 3), "Settings button should exist")
        settingsButton.tap()

        // Verify settings loaded
        XCTAssertTrue(app.staticTexts["Color Palette"].waitForExistence(timeout: 2),
                      "Settings should show Color Palette section")

        // Check for Parent Zone
        let parentZone = app.staticTexts["Parent Zone"]
        XCTAssertTrue(parentZone.waitForExistence(timeout: 2),
                      "Parent Zone should be accessible")
    }

    func testParentZoneFeatures() throws {
        let agent = ParentAgent(app: app)

        agent.navigateToHome()
        agent.navigateToSettings()

        // Access Parent Zone
        let parentZone = app.staticTexts["Parent Zone"]
        if parentZone.waitForExistence(timeout: 2) {
            parentZone.tap()

            // Verify Parent Zone features
            XCTAssertTrue(app.staticTexts["Time Limits"].waitForExistence(timeout: 2),
                          "Time Limits section should exist")
            XCTAssertTrue(app.staticTexts["Child Profiles"].waitForExistence(timeout: 2),
                          "Child Profiles section should exist")
        }
    }

    // MARK: - Multi-Persona Tests

    func testAllPersonasSequentially() throws {
        var results: [PersonaTestResult] = []

        // Test Young Child
        let youngChild = YoungChildAgent(app: app)
        let youngResult = try youngChild.runTestScenario()
        results.append(youngResult)

        // Restart app for clean state
        app.terminate()
        app.launch()

        // Test Older Child
        let olderChild = OlderChildAgent(app: app)
        let olderResult = try olderChild.runTestScenario()
        results.append(olderResult)

        // Restart app
        app.terminate()
        app.launch()

        // Test Parent
        let parent = ParentAgent(app: app)
        let parentResult = try parent.runTestScenario()
        results.append(parentResult)

        // Print all results
        print("\n" + String(repeating: "═", count: 50))
        print("MULTI-PERSONA TEST SUMMARY")
        print(String(repeating: "═", count: 50))
        for result in results {
            print(result.summary)
        }

        // Assert all passed
        for result in results {
            XCTAssertTrue(result.passed, "\(result.persona.rawValue) scenario failed: \(result.failureReason ?? "unknown")")
        }
    }

    // MARK: - Stress Tests

    func testRapidColorSwitching() throws {
        let agent = OlderChildAgent(app: app)

        agent.navigateToHome()
        agent.selectCategory("Animals")

        let pages = app.scrollViews.buttons
        if pages.count > 0 {
            pages.element(boundBy: 0).tap()
        }

        let canvas = app.images.firstMatch
        XCTAssertTrue(canvas.waitForExistence(timeout: 3))

        // Rapid color switching (stress test)
        for _ in 0..<20 {
            agent.selectColor(at: Int.random(in: 0..<12))
            agent.fillRegion(at: CGPoint(
                x: CGFloat.random(in: 0.2...0.8),
                y: CGFloat.random(in: 0.2...0.8)
            ))
        }

        XCTAssertTrue(app.exists, "App should remain stable after stress test")
    }

    func testNavigationStress() throws {
        let agent = UITestAgent(persona: .olderChild, app: app)

        // Rapid navigation between screens
        for _ in 0..<5 {
            agent.navigateToHome()
            agent.navigateToGallery()
            agent.navigateToHome()

            let categories = ["Animals", "Vehicles", "Dinosaurs"]
            for category in categories {
                agent.selectCategory(category)
                agent.goBack()
            }
        }

        XCTAssertTrue(app.exists, "App should handle rapid navigation")
    }
}

// MARK: - Accessibility Tests with Personas
final class PersonaAccessibilityTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testLargeTargetsForYoungChild() throws {
        // Verify touch targets are large enough for young children
        let agent = YoungChildAgent(app: app)
        agent.navigateToHome()

        // Check category card sizes (should be easily tappable)
        let categories = app.scrollViews.buttons
        for i in 0..<min(3, categories.count) {
            let category = categories.element(boundBy: i)
            let frame = category.frame
            XCTAssertGreaterThan(frame.width, 80, "Category cards should be wide enough")
            XCTAssertGreaterThan(frame.height, 80, "Category cards should be tall enough")
        }
    }

    func testColorButtonsAccessible() throws {
        let agent = OlderChildAgent(app: app)
        agent.navigateToHome()
        agent.selectCategory("Animals")

        let pages = app.scrollViews.buttons
        if pages.count > 0 {
            pages.element(boundBy: 0).tap()
        }

        // Verify color buttons exist and are tappable
        let colorButtons = app.scrollViews.buttons
        XCTAssertGreaterThan(colorButtons.count, 0, "Color buttons should exist")

        // Each color button should be reasonably sized
        for i in 0..<min(5, colorButtons.count) {
            let button = colorButtons.element(boundBy: i)
            if button.exists {
                XCTAssertTrue(button.isHittable, "Color button \(i) should be hittable")
            }
        }
    }
}
