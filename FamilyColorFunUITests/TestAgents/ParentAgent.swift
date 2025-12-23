import XCTest

// MARK: - Parent Agent (Ages 25-45)
/// Simulates a parent's interaction with the app:
/// - Checks settings and parental controls
/// - Reviews child's gallery
/// - Tests time limit features
/// - Verifies app safety features
/// - Quick navigation to verify functionality
/// - May set up child profiles
class ParentAgent: UITestAgent {

    init(app: XCUIApplication) {
        super.init(persona: .parent, app: app)
    }

    override func runTestScenario() throws -> PersonaTestResult {
        print("👩‍👧 Starting Parent Test Scenario...")

        do {
            // Step 1: Quick app overview
            try reviewAppOverview()

            // Step 2: Check settings
            try exploreSettings()

            // Step 3: Access Parent Zone
            try accessParentZone()

            // Step 4: Review gallery
            try reviewChildGallery()

            // Step 5: Verify coloring works
            try verifyColoringWorks()

            // Step 6: Test share/export features
            try testSharingFeatures()

            return buildResult(passed: true)

        } catch {
            return buildResult(passed: false, failureReason: error.localizedDescription)
        }
    }

    // MARK: - Parent Behaviors

    private func reviewAppOverview() throws {
        navigateToHome()
        takeScreenshot(name: "app_overview")

        // Parent quickly scans categories
        guard app.navigationBars["Color Fun"].waitForExistence(timeout: 3) else {
            throw TestError.navigationFailed("Home screen not loaded")
        }

        // Verify tabs exist
        guard verifyTabBarVisible() else {
            throw TestError.elementNotFound("Tab bar")
        }

        logAction(.navigate, target: "Reviewed app overview")
    }

    private func exploreSettings() throws {
        // Find and tap settings gear
        let settingsButton = app.buttons["gearshape"]
        guard settingsButton.waitForExistence(timeout: 3) else {
            throw TestError.elementNotFound("Settings button")
        }

        settingsButton.tap()
        wait(for: persona.tapSpeed.delay)

        takeScreenshot(name: "settings_main")

        // Verify settings sections exist
        let settingsChecks = ["Color Palette", "Age Mode", "Sound Effects"]
        for setting in settingsChecks {
            let element = app.staticTexts[setting]
            if element.waitForExistence(timeout: 2) {
                logAction(.settings, target: "Verified: \(setting)")
            }
        }

        // Check different palettes
        let paletteOptions = ["Classic Rainbow", "Pastel Dreams", "Bold & Bright"]
        for palette in paletteOptions {
            let paletteButton = app.staticTexts[palette]
            if paletteButton.exists {
                paletteButton.tap()
                wait(for: 0.3)
                logAction(.tap, target: "Selected palette: \(palette)")
            }
        }

        takeScreenshot(name: "settings_modified")
    }

    private func accessParentZone() throws {
        // Look for Parent Zone in settings
        let parentZoneButton = app.staticTexts["Parent Zone"]

        if parentZoneButton.waitForExistence(timeout: 2) {
            parentZoneButton.tap()
            wait(for: persona.tapSpeed.delay)

            takeScreenshot(name: "parent_zone")

            // Check Parent Zone features
            let parentFeatures = ["Time Limits", "Child Profiles", "Usage Statistics"]
            for feature in parentFeatures {
                let element = app.staticTexts[feature]
                if element.waitForExistence(timeout: 2) {
                    logAction(.settings, target: "Parent Zone: \(feature) exists")
                }
            }

            // Test time limit toggle if visible
            let timeLimitToggle = app.switches["Daily Time Limit"]
            if timeLimitToggle.exists {
                timeLimitToggle.tap()
                wait(for: 0.5)
                timeLimitToggle.tap()  // Toggle back
                logAction(.tap, target: "Tested time limit toggle")
            }

            takeScreenshot(name: "parent_zone_explored")

            // Dismiss Parent Zone
            dismissSheet()
        }

        // Dismiss settings
        dismissSheet()
    }

    private func reviewChildGallery() throws {
        navigateToGallery()

        guard app.navigationBars["My Masterpieces"].waitForExistence(timeout: 3) ||
              app.navigationBars["My Gallery"].waitForExistence(timeout: 3) else {
            // Gallery might be empty
            takeScreenshot(name: "gallery_empty")
            logAction(.navigate, target: "Gallery (may be empty)")
            return
        }

        takeScreenshot(name: "gallery_review")

        // Scroll through saved artwork
        let galleryScroll = app.scrollViews.firstMatch
        if galleryScroll.exists {
            galleryScroll.swipeUp()
            wait(for: 0.5)
            galleryScroll.swipeDown()
            wait(for: 0.5)
        }

        // Check for action buttons on artwork cards
        let shareButtons = app.buttons["square.and.arrow.up"]
        if shareButtons.firstMatch.exists {
            logAction(.navigate, target: "Share buttons available")
        }

        logAction(.navigate, target: "Reviewed child's gallery")
    }

    private func verifyColoringWorks() throws {
        navigateToHome()

        // Quick test of coloring
        selectCategory("Animals")

        let firstPage = app.scrollViews.buttons.firstMatch
        if firstPage.waitForExistence(timeout: 2) {
            firstPage.tap()
            wait(for: persona.tapSpeed.delay)
        }

        let canvas = app.images.firstMatch
        if canvas.waitForExistence(timeout: 3) {
            takeScreenshot(name: "canvas_test_start")

            // Quick functional test
            selectColor(at: 0)
            fillRegion(at: CGPoint(x: 0.5, y: 0.5))

            selectColor(at: 3)
            fillRegion(at: CGPoint(x: 0.3, y: 0.4))

            // Test undo
            tapUndo()

            takeScreenshot(name: "canvas_test_complete")
            logAction(.fill, target: "Verified coloring functionality")
        }
    }

    private func testSharingFeatures() throws {
        // Test share button
        let shareButton = app.buttons["square.and.arrow.up"]
        if shareButton.waitForExistence(timeout: 2) {
            shareButton.tap()
            wait(for: 1.0)

            takeScreenshot(name: "share_sheet")

            // Dismiss share sheet (tap outside or cancel)
            let cancelButton = app.buttons["Cancel"]
            if cancelButton.exists {
                cancelButton.tap()
            } else {
                // Tap outside to dismiss
                app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)).tap()
            }

            wait(for: 0.5)
            logAction(.share, target: "Tested share feature")
        }

        // Go back to home
        goBack()
        goBack()

        takeScreenshot(name: "final_parent_view")
    }
}
