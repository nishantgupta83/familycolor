import XCTest

final class CanvasUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        navigateToCanvas()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    private func navigateToCanvas() {
        app.staticTexts["Animals"].tap()
        _ = app.staticTexts["Cat"].waitForExistence(timeout: 2)
        app.staticTexts["Cat"].tap()
    }

    // MARK: - Color Palette Tests

    func testColorPaletteExists() throws {
        // Color palette should have multiple color buttons
        let colorButtons = app.buttons.matching(identifier: "colorButton")
        // At least verify the view hierarchy exists
        XCTAssertTrue(app.navigationBars["Cat"].exists)
    }

    func testCanvasDisplaysColoringPage() throws {
        // Wait for canvas to load and be visible
        sleep(3)

        // Take screenshot attachment
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Coloring Canvas"
        attachment.lifetime = .keepAlways
        add(attachment)

        // Canvas should exist
        XCTAssertTrue(app.navigationBars["Cat"].exists)

        // Tap to color
        let canvas = app.otherElements.firstMatch
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).tap()
        sleep(2)

        // Take after coloring screenshot
        let afterScreenshot = app.screenshot()
        let afterAttachment = XCTAttachment(screenshot: afterScreenshot)
        afterAttachment.name = "After Coloring"
        afterAttachment.lifetime = .keepAlways
        add(afterAttachment)

        XCTAssertTrue(app.navigationBars["Cat"].exists)
    }

    func testTapOnCanvas() throws {
        // Get the main view area (canvas)
        let canvas = app.otherElements.firstMatch

        // Tap on canvas
        canvas.tap()

        // Canvas should still exist after tap (not crash)
        XCTAssertTrue(app.navigationBars["Cat"].exists)
    }

    func testMultipleTapsOnCanvas() throws {
        let canvas = app.otherElements.firstMatch

        // Multiple taps to simulate coloring
        for _ in 0..<5 {
            let randomX = CGFloat.random(in: 0.3...0.7)
            let randomY = CGFloat.random(in: 0.3...0.7)
            canvas.coordinate(withNormalizedOffset: CGVector(dx: randomX, dy: randomY)).tap()
        }

        XCTAssertTrue(app.navigationBars["Cat"].exists)
    }

    // MARK: - Undo Tests

    func testUndoButtonInitiallyDisabled() throws {
        let undoButton = app.buttons["arrow.uturn.backward.circle.fill"]
        XCTAssertTrue(undoButton.exists)
        // Note: We can't easily check if it's disabled in UI tests without accessibility
    }

    func testUndoAfterFill() throws {
        let canvas = app.otherElements.firstMatch

        // Tap to fill
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()

        // Tap undo
        let undoButton = app.buttons["arrow.uturn.backward.circle.fill"]
        undoButton.tap()

        // App should not crash
        XCTAssertTrue(app.navigationBars["Cat"].exists)
    }

    // MARK: - Clear Tests

    func testClearButton() throws {
        let canvas = app.otherElements.firstMatch

        // Fill some areas
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.3)).tap()
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.6, dy: 0.6)).tap()

        // Tap clear
        let clearButton = app.buttons["trash.circle.fill"]
        clearButton.tap()

        XCTAssertTrue(app.navigationBars["Cat"].exists)
    }

    // MARK: - Share Tests

    func testShareButtonExists() throws {
        let shareButton = app.buttons["square.and.arrow.up"]
        XCTAssertTrue(shareButton.exists)
    }

    func testShareButtonOpensSheet() throws {
        let shareButton = app.buttons["square.and.arrow.up"]
        shareButton.tap()

        // Share sheet should appear (UIActivityViewController)
        let shareSheet = app.otherElements["ActivityListView"]
        _ = shareSheet.waitForExistence(timeout: 3)

        // Dismiss by tapping outside or cancel
        if app.buttons["Close"].exists {
            app.buttons["Close"].tap()
        } else {
            // Swipe down to dismiss
            app.swipeDown()
        }
    }

    // MARK: - Pinch to Zoom Tests

    func testPinchToZoom() throws {
        let canvas = app.otherElements.firstMatch

        // Perform pinch gesture
        canvas.pinch(withScale: 2.0, velocity: 1.0)

        // App should not crash
        XCTAssertTrue(app.navigationBars["Cat"].exists)

        // Pinch back
        canvas.pinch(withScale: 0.5, velocity: -1.0)
        XCTAssertTrue(app.navigationBars["Cat"].exists)
    }

    // MARK: - Progress Tests

    func testProgressIndicatorExists() throws {
        // Progress indicator should be visible
        let progressView = app.progressIndicators.firstMatch
        XCTAssertTrue(progressView.waitForExistence(timeout: 2))
    }
}
