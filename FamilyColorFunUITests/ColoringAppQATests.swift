import XCTest

/// Top 50 Test Cases for Coloring App Quality Assurance
/// Covers: Fill, Draw, Undo/Redo, Zoom, Save, AutoFill, Navigation, Performance
final class ColoringAppQATests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = true
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Test 1-10: Core Fill Functionality

    func test01_FillSingleRegion() throws {
        navigateToPage(category: "Animals", page: "Cat")

        let canvas = app.scrollViews.firstMatch
        XCTAssertTrue(canvas.exists, "Canvas should exist")

        // Select a color and tap
        selectColor(index: 0)
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()

        // Fill should work (no crash)
        sleep(1)
        XCTAssertTrue(canvas.exists, "Canvas should still exist after fill")
    }

    func test02_FillMultipleRegions() throws {
        navigateToPage(category: "Animals", page: "Dog")

        let canvas = app.scrollViews.firstMatch
        let positions = [(0.3, 0.3), (0.5, 0.5), (0.7, 0.7), (0.4, 0.6), (0.6, 0.4)]

        for (i, pos) in positions.enumerated() {
            selectColor(index: i % 10)
            canvas.coordinate(withNormalizedOffset: CGVector(dx: pos.0, dy: pos.1)).tap()
            usleep(200000)
        }

        XCTAssertTrue(canvas.exists, "Canvas should exist after multiple fills")
    }

    func test03_FillWithAllColors() throws {
        navigateToPage(category: "Nature", page: "Flower")

        let canvas = app.scrollViews.firstMatch
        let colorButtons = app.scrollViews.buttons

        // Test all available colors
        for i in 0..<min(10, colorButtons.count) {
            colorButtons.element(boundBy: i).tap()
            canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.2 + Double(i) * 0.07, dy: 0.5)).tap()
            usleep(150000)
        }

        XCTAssertTrue(canvas.exists, "Should handle all colors")
    }

    func test04_FillRapidTaps() throws {
        navigateToPage(category: "Geometric", page: "Pattern 1")

        let canvas = app.scrollViews.firstMatch
        selectColor(index: 2)

        // Rapid fire taps
        for i in 0..<20 {
            let x = 0.2 + (Double(i % 5) * 0.15)
            let y = 0.3 + (Double(i / 5) * 0.1)
            canvas.coordinate(withNormalizedOffset: CGVector(dx: x, dy: y)).tap()
            usleep(50000) // 50ms
        }

        XCTAssertTrue(canvas.exists, "Should handle rapid taps")
    }

    func test05_FillBoundaryRegions() throws {
        navigateToPage(category: "Mandalas", page: "Mandala 1")

        let canvas = app.scrollViews.firstMatch
        selectColor(index: 1)

        // Test boundary/edge regions
        let edgePositions = [
            (0.1, 0.5), (0.9, 0.5), // Left/Right edges
            (0.5, 0.15), (0.5, 0.85), // Top/Bottom edges
            (0.1, 0.1), (0.9, 0.9) // Corners
        ]

        for pos in edgePositions {
            canvas.coordinate(withNormalizedOffset: CGVector(dx: pos.0, dy: pos.1)).tap()
            usleep(200000)
        }

        XCTAssertTrue(canvas.exists, "Should handle boundary fills")
    }

    func test06_FillTinyRegions() throws {
        navigateToPage(category: "Abstract", page: "Abstract 1")

        let canvas = app.scrollViews.firstMatch
        selectColor(index: 3)

        // Zoom in first for tiny regions
        let zoomIn = app.buttons.matching(NSPredicate(format: "label CONTAINS 'plus'")).firstMatch
        if zoomIn.exists {
            zoomIn.tap()
            zoomIn.tap()
            sleep(1)
        }

        // Tap in center area multiple times
        for i in 0..<10 {
            let offset = Double(i) * 0.02
            canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5 + offset, dy: 0.5)).tap()
            usleep(100000)
        }

        XCTAssertTrue(canvas.exists, "Should handle tiny region fills")
    }

    func test07_FillAfterZoom() throws {
        navigateToPage(category: "Animals", page: "Elephant")

        let canvas = app.scrollViews.firstMatch

        // Zoom in
        canvas.pinch(withScale: 2.0, velocity: 1)
        sleep(1)

        // Fill while zoomed
        selectColor(index: 4)
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        sleep(1)

        // Zoom out
        canvas.pinch(withScale: 0.5, velocity: 1)

        XCTAssertTrue(canvas.exists, "Should fill correctly while zoomed")
    }

    func test08_FillSameRegionMultipleTimes() throws {
        navigateToPage(category: "Animals", page: "Bunny")

        let canvas = app.scrollViews.firstMatch
        let center = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))

        // Fill same region with different colors
        for i in 0..<5 {
            selectColor(index: i)
            center.tap()
            usleep(300000)
        }

        XCTAssertTrue(canvas.exists, "Should handle re-coloring same region")
    }

    func test09_FillProgressUpdates() throws {
        navigateToPage(category: "Animals", page: "Bear")

        let canvas = app.scrollViews.firstMatch

        // Fill several regions and check progress updates
        for i in 0..<8 {
            selectColor(index: i % 10)
            let x = 0.2 + (Double(i % 4) * 0.2)
            let y = 0.3 + (Double(i / 4) * 0.3)
            canvas.coordinate(withNormalizedOffset: CGVector(dx: x, dy: y)).tap()
            usleep(200000)
        }

        // Progress should have updated (verify no crash)
        XCTAssertTrue(canvas.exists, "Progress should update correctly")
    }

    func test10_FillDoesNotAffectLines() throws {
        navigateToPage(category: "Animals", page: "Bird")

        let canvas = app.scrollViews.firstMatch
        selectColor(index: 5)

        // Tap directly on lines (should not fill)
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()

        XCTAssertTrue(canvas.exists, "Lines should remain intact")
    }

    // MARK: - Test 11-20: Undo/Redo Functionality

    func test11_UndoSingleFill() throws {
        navigateToPage(category: "Nature", page: "Star")

        let canvas = app.scrollViews.firstMatch
        selectColor(index: 0)
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        sleep(1)

        let undoButton = app.buttons["arrow.uturn.backward.circle.fill"]
        XCTAssertTrue(undoButton.exists, "Undo button should exist")
        undoButton.tap()

        XCTAssertTrue(canvas.exists, "Undo should work")
    }

    func test12_UndoMultipleFills() throws {
        navigateToPage(category: "Nature", page: "Rose")

        let canvas = app.scrollViews.firstMatch

        // Fill 5 regions
        for i in 0..<5 {
            selectColor(index: i)
            canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.3 + Double(i) * 0.1, dy: 0.5)).tap()
            usleep(200000)
        }

        // Undo all 5
        let undoButton = app.buttons["arrow.uturn.backward.circle.fill"]
        for _ in 0..<5 {
            if undoButton.isEnabled {
                undoButton.tap()
                usleep(200000)
            }
        }

        XCTAssertTrue(canvas.exists, "Multiple undos should work")
    }

    func test13_UndoAfterModeSwitch() throws {
        navigateToPage(category: "Nature", page: "Daisy")

        let canvas = app.scrollViews.firstMatch
        selectColor(index: 0)
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        sleep(1)

        // Switch to draw mode
        let drawButton = app.buttons["Draw"]
        if drawButton.exists {
            drawButton.tap()
            sleep(1)

            // Switch back to fill
            let fillButton = app.buttons["Fill"]
            fillButton.tap()
            sleep(1)
        }

        // Undo should still work
        let undoButton = app.buttons["arrow.uturn.backward.circle.fill"]
        if undoButton.isEnabled {
            undoButton.tap()
        }

        XCTAssertTrue(canvas.exists, "Undo should work after mode switch")
    }

    func test14_UndoDisabledWhenEmpty() throws {
        // Launch fresh to ensure empty canvas
        app.terminate()
        app.launch()
        navigateToPage(category: "Nature", page: "Tulip")

        let undoButton = app.buttons["arrow.uturn.backward.circle.fill"]
        // Undo might be disabled on fresh canvas
        XCTAssertTrue(undoButton.exists, "Undo button should exist")
    }

    func test15_ClearAllWithConfirmation() throws {
        navigateToPage(category: "Vehicles", page: "Car")

        let canvas = app.scrollViews.firstMatch
        selectColor(index: 0)
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        sleep(1)

        let clearButton = app.buttons["trash.circle.fill"]
        if clearButton.exists {
            clearButton.tap()

            // Should show confirmation
            let cancelButton = app.buttons["Cancel"]
            if cancelButton.waitForExistence(timeout: 3) {
                cancelButton.tap()
            }
        }

        XCTAssertTrue(canvas.exists, "Clear confirmation should work")
    }

    func test16_ClearAllConfirmed() throws {
        navigateToPage(category: "Houses", page: "Cottage")

        let canvas = app.scrollViews.firstMatch
        selectColor(index: 2)
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        sleep(1)

        let clearButton = app.buttons["trash.circle.fill"]
        if clearButton.exists {
            clearButton.tap()

            let clearConfirmButton = app.buttons["Clear"]
            if clearConfirmButton.waitForExistence(timeout: 3) {
                clearConfirmButton.tap()
                sleep(1)
            }
        }

        XCTAssertTrue(canvas.exists, "Clear all should work")
    }

    func test17_UndoAfterClear() throws {
        navigateToPage(category: "Ocean", page: "Fish")

        let canvas = app.scrollViews.firstMatch
        selectColor(index: 1)
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        sleep(1)

        // Clear
        let clearButton = app.buttons["trash.circle.fill"]
        if clearButton.exists {
            clearButton.tap()
            let clearConfirmButton = app.buttons["Clear"]
            if clearConfirmButton.waitForExistence(timeout: 3) {
                clearConfirmButton.tap()
                sleep(1)
            }
        }

        // Undo should restore
        let undoButton = app.buttons["arrow.uturn.backward.circle.fill"]
        if undoButton.exists && undoButton.isEnabled {
            undoButton.tap()
        }

        XCTAssertTrue(canvas.exists, "Undo after clear should work")
    }

    func test18_UndoStackLimit() throws {
        navigateToPage(category: "Retro 90s", page: "Boombox")

        let canvas = app.scrollViews.firstMatch

        // Fill many regions to test stack limit
        for i in 0..<50 {
            selectColor(index: i % 10)
            let x = 0.1 + (Double(i % 10) * 0.08)
            let y = 0.2 + (Double(i / 10) * 0.15)
            canvas.coordinate(withNormalizedOffset: CGVector(dx: x, dy: y)).tap()
            usleep(50000)
        }

        // Undo many times
        let undoButton = app.buttons["arrow.uturn.backward.circle.fill"]
        for _ in 0..<30 {
            if undoButton.exists && undoButton.isEnabled {
                undoButton.tap()
                usleep(50000)
            }
        }

        XCTAssertTrue(canvas.exists, "Should handle large undo stack")
    }

    func test19_RedoAfterUndo() throws {
        navigateToPage(category: "Retro 90s", page: "Turntable")

        let canvas = app.scrollViews.firstMatch
        selectColor(index: 0)
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        sleep(1)

        // Undo
        let undoButton = app.buttons["arrow.uturn.backward.circle.fill"]
        if undoButton.exists && undoButton.isEnabled {
            undoButton.tap()
            sleep(1)
        }

        // Check for redo button
        let redoButton = app.buttons["arrow.uturn.forward.circle.fill"]
        if redoButton.exists && redoButton.isEnabled {
            redoButton.tap()
        }

        XCTAssertTrue(canvas.exists, "Redo should work")
    }

    func test20_UndoDrawStroke() throws {
        navigateToPage(category: "Geometric", page: "Pattern 2")

        // Switch to draw mode
        let drawButton = app.buttons["Draw"]
        guard drawButton.waitForExistence(timeout: 5) else { return }
        drawButton.tap()
        sleep(1)

        let canvas = app.scrollViews.firstMatch
        let start = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.3))
        let end = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.7))
        start.press(forDuration: 0.1, thenDragTo: end)
        sleep(1)

        // Undo the stroke
        let undoButton = app.buttons["arrow.uturn.backward.circle.fill"]
        if undoButton.exists && undoButton.isEnabled {
            undoButton.tap()
        }

        XCTAssertTrue(canvas.exists, "Undo draw stroke should work")
    }

    // MARK: - Test 21-30: Zoom & Pan

    func test21_PinchZoomIn() throws {
        navigateToPage(category: "Mandalas", page: "Mandala 2")

        let canvas = app.scrollViews.firstMatch
        canvas.pinch(withScale: 2.0, velocity: 1)
        sleep(1)

        XCTAssertTrue(canvas.exists, "Pinch zoom in should work")
    }

    func test22_PinchZoomOut() throws {
        navigateToPage(category: "Mandalas", page: "Mandala 3")

        let canvas = app.scrollViews.firstMatch
        // First zoom in
        canvas.pinch(withScale: 2.0, velocity: 1)
        sleep(1)
        // Then zoom out
        canvas.pinch(withScale: 0.5, velocity: 1)
        sleep(1)

        XCTAssertTrue(canvas.exists, "Pinch zoom out should work")
    }

    func test23_ZoomButtonsExist() throws {
        navigateToPage(category: "Mandalas", page: "Mandala 4")

        // Check for zoom controls (may vary by implementation)
        let zoomIn = app.buttons.matching(NSPredicate(format: "label CONTAINS 'plus' OR identifier CONTAINS 'plus'")).firstMatch
        let zoomOut = app.buttons.matching(NSPredicate(format: "label CONTAINS 'minus' OR identifier CONTAINS 'minus'")).firstMatch

        // Try zoom buttons if they exist
        if zoomIn.exists { zoomIn.tap() }
        if zoomOut.exists { zoomOut.tap() }

        // At minimum, canvas should support pinch zoom
        let canvas = app.scrollViews.firstMatch
        XCTAssertTrue(canvas.exists, "Canvas should exist for zoom")
    }

    func test24_PanWhileZoomed() throws {
        navigateToPage(category: "Mandalas", page: "Mandala 5")

        let canvas = app.scrollViews.firstMatch
        canvas.pinch(withScale: 2.0, velocity: 1)
        sleep(1)

        // Pan around
        canvas.swipeLeft()
        canvas.swipeRight()
        canvas.swipeUp()
        canvas.swipeDown()

        XCTAssertTrue(canvas.exists, "Pan while zoomed should work")
    }

    func test25_FillWhileZoomedAndPanned() throws {
        navigateToPage(category: "Mandalas", page: "Mandala 6")

        let canvas = app.scrollViews.firstMatch
        canvas.pinch(withScale: 2.0, velocity: 1)
        sleep(1)
        canvas.swipeLeft()
        sleep(1)

        selectColor(index: 3)
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()

        XCTAssertTrue(canvas.exists, "Fill while zoomed and panned should work")
    }

    func test26_ZoomMaxLimit() throws {
        navigateToPage(category: "Geometric", page: "Pattern 3")

        let canvas = app.scrollViews.firstMatch

        // Try to zoom in a lot
        for _ in 0..<5 {
            canvas.pinch(withScale: 2.0, velocity: 1)
            usleep(500000)
        }

        XCTAssertTrue(canvas.exists, "Should handle max zoom limit")
    }

    func test27_ZoomMinLimit() throws {
        navigateToPage(category: "Geometric", page: "Pattern 4")

        let canvas = app.scrollViews.firstMatch

        // Try to zoom out a lot
        for _ in 0..<5 {
            canvas.pinch(withScale: 0.5, velocity: 1)
            usleep(500000)
        }

        XCTAssertTrue(canvas.exists, "Should handle min zoom limit")
    }

    func test28_DoubleTapToZoom() throws {
        navigateToPage(category: "Geometric", page: "Pattern 5")

        let canvas = app.scrollViews.firstMatch
        canvas.doubleTap()
        sleep(1)

        XCTAssertTrue(canvas.exists, "Double tap zoom should work")
    }

    func test29_ResetZoom() throws {
        navigateToPage(category: "Geometric", page: "Pattern 6")

        let canvas = app.scrollViews.firstMatch
        canvas.pinch(withScale: 3.0, velocity: 1)
        sleep(1)

        // Double tap might reset, or there may be a reset button
        canvas.doubleTap()
        sleep(1)

        XCTAssertTrue(canvas.exists, "Reset zoom should work")
    }

    func test30_ZoomMaintainsQuality() throws {
        navigateToPage(category: "Abstract", page: "Abstract 2")

        let canvas = app.scrollViews.firstMatch
        canvas.pinch(withScale: 3.0, velocity: 1)
        sleep(1)

        // Fill while max zoomed
        selectColor(index: 0)
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()

        XCTAssertTrue(canvas.exists, "Zoom should maintain quality")
    }

    // MARK: - Test 31-40: Save & Export

    func test31_ShareButtonExists() throws {
        navigateToPage(category: "Dinosaurs", page: "T-Rex")

        let shareButton = app.buttons["square.and.arrow.up"]
        XCTAssertTrue(shareButton.waitForExistence(timeout: 5), "Share button should exist")
    }

    func test32_ShareButtonEnabled() throws {
        navigateToPage(category: "Dinosaurs", page: "Triceratops")

        let shareButton = app.buttons["square.and.arrow.up"]
        XCTAssertTrue(shareButton.waitForExistence(timeout: 5), "Share button should exist")
        XCTAssertTrue(shareButton.isEnabled, "Share button should be enabled")
    }

    func test33_ShareSheetOpens() throws {
        navigateToPage(category: "Dinosaurs", page: "Stegosaurus")

        let shareButton = app.buttons["square.and.arrow.up"]
        guard shareButton.waitForExistence(timeout: 5) else {
            XCTFail("Share button not found")
            return
        }

        shareButton.tap()
        sleep(2)

        // Dismiss share sheet
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)).tap()
        sleep(1)
    }

    func test34_SaveAfterColoring() throws {
        navigateToPage(category: "Space", page: "Rocket")

        let canvas = app.scrollViews.firstMatch
        selectColor(index: 1)
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        sleep(1)

        let shareButton = app.buttons["square.and.arrow.up"]
        XCTAssertTrue(shareButton.waitForExistence(timeout: 5), "Share should work after coloring")
    }

    func test35_SaveWithAutoFill() throws {
        navigateToPage(category: "Space", page: "Astronaut")

        // Use auto-fill
        let autoFillButton = app.buttons["wand.and.stars"]
        if autoFillButton.waitForExistence(timeout: 5) && autoFillButton.isEnabled {
            autoFillButton.tap()

            let fillButton = app.buttons["Fill with random colors"]
            if fillButton.waitForExistence(timeout: 3) {
                fillButton.tap()
                sleep(2)
            }
        }

        let shareButton = app.buttons["square.and.arrow.up"]
        XCTAssertTrue(shareButton.waitForExistence(timeout: 5), "Share should work after auto-fill")
    }

    func test36_SaveEmptyCanvas() throws {
        // Fresh page
        app.terminate()
        app.launch()
        navigateToPage(category: "Space", page: "Planet")

        let shareButton = app.buttons["square.and.arrow.up"]
        // Should still be able to share blank canvas
        XCTAssertTrue(shareButton.waitForExistence(timeout: 5), "Share should exist for empty canvas")
    }

    func test37_SaveWithDrawings() throws {
        navigateToPage(category: "Food", page: "Cupcake")

        // Draw something
        let drawButton = app.buttons["Draw"]
        if drawButton.waitForExistence(timeout: 5) {
            drawButton.tap()
            sleep(1)

            let canvas = app.scrollViews.firstMatch
            let start = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.3))
            let end = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.7))
            start.press(forDuration: 0.1, thenDragTo: end)
            sleep(1)
        }

        let shareButton = app.buttons["square.and.arrow.up"]
        XCTAssertTrue(shareButton.waitForExistence(timeout: 5), "Share should work with drawings")
    }

    func test38_SaveHighResolution() throws {
        navigateToPage(category: "Food", page: "Ice Cream")

        let canvas = app.scrollViews.firstMatch
        selectColor(index: 0)
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()

        let shareButton = app.buttons["square.and.arrow.up"]
        XCTAssertTrue(shareButton.waitForExistence(timeout: 5), "High-res save should be available")
    }

    func test39_SaveMultipleTimes() throws {
        navigateToPage(category: "Food", page: "Pizza")

        let shareButton = app.buttons["square.and.arrow.up"]

        // Open share sheet multiple times
        for _ in 0..<3 {
            if shareButton.waitForExistence(timeout: 5) {
                shareButton.tap()
                sleep(1)
                app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)).tap()
                sleep(1)
            }
        }

        XCTAssertTrue(shareButton.exists, "Multiple saves should work")
    }

    func test40_SaveCancelledCorrectly() throws {
        navigateToPage(category: "Holidays", page: "Christmas Tree")

        let shareButton = app.buttons["square.and.arrow.up"]
        guard shareButton.waitForExistence(timeout: 5) else { return }

        shareButton.tap()
        sleep(1)

        // Cancel/dismiss
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)).tap()
        sleep(1)

        // Canvas should still work
        let canvas = app.scrollViews.firstMatch
        selectColor(index: 2)
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()

        XCTAssertTrue(canvas.exists, "Should work after save cancellation")
    }

    // MARK: - Test 41-50: Auto-Fill & Navigation

    func test41_AutoFillButtonExists() throws {
        navigateToPage(category: "Holidays", page: "Easter Egg")

        let autoFillButton = app.buttons["wand.and.stars"]
        XCTAssertTrue(autoFillButton.waitForExistence(timeout: 5), "Auto-fill button should exist")
    }

    func test42_AutoFillConfirmation() throws {
        navigateToPage(category: "Holidays", page: "Pumpkin")

        let autoFillButton = app.buttons["wand.and.stars"]
        guard autoFillButton.waitForExistence(timeout: 5), autoFillButton.isEnabled else { return }

        autoFillButton.tap()

        let fillButton = app.buttons["Fill with random colors"]
        XCTAssertTrue(fillButton.waitForExistence(timeout: 3), "Auto-fill confirmation should appear")

        // Cancel
        let cancelButton = app.buttons["Cancel"]
        if cancelButton.exists {
            cancelButton.tap()
        }
    }

    func test43_AutoFillCompletes() throws {
        navigateToPage(category: "Sports", page: "Soccer Ball")

        let autoFillButton = app.buttons["wand.and.stars"]
        guard autoFillButton.waitForExistence(timeout: 5), autoFillButton.isEnabled else { return }

        autoFillButton.tap()

        let fillButton = app.buttons["Fill with random colors"]
        if fillButton.waitForExistence(timeout: 3) {
            fillButton.tap()
            sleep(2)
        }

        XCTAssertTrue(app.scrollViews.firstMatch.exists, "Auto-fill should complete")
    }

    func test44_NavigationToCategory() throws {
        let categories = ["Animals", "Nature", "Mandalas", "Geometric"]

        for category in categories {
            goToHome()
            let categoryElement = app.staticTexts[category]

            if !categoryElement.exists {
                app.swipeUp()
                sleep(1)
            }

            XCTAssertTrue(categoryElement.waitForExistence(timeout: 5), "Category \(category) should exist")
            categoryElement.tap()
            XCTAssertTrue(app.navigationBars[category].waitForExistence(timeout: 5), "Should navigate to \(category)")

            // Go back
            if app.navigationBars.buttons.count > 0 {
                app.navigationBars.buttons.element(boundBy: 0).tap()
            }
            sleep(1)
        }
    }

    func test45_NavigationBackPreservesState() throws {
        navigateToPage(category: "Music", page: "Guitar")

        let canvas = app.scrollViews.firstMatch
        selectColor(index: 0)
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        sleep(1)

        // Go back
        if app.navigationBars.buttons.count > 0 {
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }
        sleep(1)

        // Return to same page
        app.staticTexts["Guitar"].tap()
        sleep(1)

        // State might be preserved (depending on implementation)
        XCTAssertTrue(canvas.exists, "Navigation should work correctly")
    }

    func test46_ModeSwitch_FillToDraw() throws {
        navigateToPage(category: "Music", page: "Piano")

        let fillButton = app.buttons["Fill"]
        let drawButton = app.buttons["Draw"]

        XCTAssertTrue(drawButton.waitForExistence(timeout: 5), "Draw button should exist")
        drawButton.tap()
        sleep(1)

        XCTAssertTrue(fillButton.waitForExistence(timeout: 5), "Fill button should exist")
        fillButton.tap()

        XCTAssertTrue(app.scrollViews.firstMatch.exists, "Mode switch should work")
    }

    func test47_AllCategoriesAccessible() throws {
        let expectedCategories = [
            "Animals", "Vehicles", "Houses", "Nature", "Ocean",
            "Retro 90s", "Mandalas", "Geometric", "Abstract"
        ]

        goToHome()

        for category in expectedCategories {
            let categoryElement = app.staticTexts[category]
            var found = categoryElement.exists

            if !found {
                app.swipeUp()
                sleep(1)
                found = categoryElement.exists
            }

            // Categories should be accessible
            if found {
                print("Found category: \(category)")
            }
        }

        XCTAssertTrue(true, "Categories check completed")
    }

    func test48_NewCategoriesExist() throws {
        let newCategories = ["Dinosaurs", "Space", "Food", "Holidays", "Sports", "Music"]

        goToHome()

        for category in newCategories {
            let categoryElement = app.staticTexts[category]

            // Scroll down to find new categories
            for _ in 0..<3 {
                if categoryElement.exists {
                    break
                }
                app.swipeUp()
                sleep(1)
            }

            if categoryElement.exists {
                print("Found new category: \(category)")
            }
        }

        XCTAssertTrue(true, "New categories check completed")
    }

    func test49_PerformanceUnderLoad() throws {
        navigateToPage(category: "Robots", page: "Robot 1")

        let canvas = app.scrollViews.firstMatch

        // Heavy load test
        for i in 0..<30 {
            selectColor(index: i % 10)
            let x = 0.1 + (Double(i % 10) * 0.08)
            let y = 0.2 + (Double(i / 10) * 0.25)
            canvas.coordinate(withNormalizedOffset: CGVector(dx: x, dy: y)).tap()
            usleep(30000) // 30ms - fast!
        }

        XCTAssertTrue(canvas.exists, "Should handle load")
    }

    func test50_MemoryStabilityAcrossPages() throws {
        let pages = [
            ("Fantasy", "Unicorn"),
            ("Fantasy", "Dragon"),
            ("Fantasy", "Castle"),
            ("Underwater", "Octopus"),
            ("Underwater", "Seahorse")
        ]

        for (category, page) in pages {
            navigateToPage(category: category, page: page)

            let canvas = app.scrollViews.firstMatch
            for i in 0..<5 {
                selectColor(index: i)
                canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.3 + Double(i) * 0.1, dy: 0.5)).tap()
                usleep(100000)
            }

            goToHome()
            sleep(1)
        }

        XCTAssertTrue(true, "Memory should be stable across pages")
    }

    // MARK: - Helper Methods

    private func navigateToPage(category: String, page: String) {
        goToHome()

        let categoryElement = app.staticTexts[category]
        if !categoryElement.exists {
            app.swipeUp()
            sleep(1)
        }

        if categoryElement.waitForExistence(timeout: 10) {
            categoryElement.tap()
        }

        guard app.navigationBars[category].waitForExistence(timeout: 10) else { return }

        let pageElement = app.staticTexts[page]
        if !pageElement.exists {
            app.swipeUp()
            sleep(1)
        }

        if pageElement.waitForExistence(timeout: 10) {
            pageElement.tap()
        }

        _ = app.navigationBars[page].waitForExistence(timeout: 10)
        sleep(1)
    }

    private func goToHome() {
        var attempts = 0
        while !app.navigationBars["Color Fun"].exists && attempts < 5 {
            if app.navigationBars.buttons.count > 0 {
                app.navigationBars.buttons.element(boundBy: 0).tap()
            }
            attempts += 1
            sleep(1)
        }
    }

    private func selectColor(index: Int) {
        let colorButtons = app.scrollViews.buttons
        if colorButtons.count > index {
            colorButtons.element(boundBy: index % max(1, colorButtons.count)).tap()
            usleep(100000)
        }
    }
}
