import XCTest

// MARK: - Older Child Agent (Ages 6-9)
/// Simulates an older child's interaction with the app:
/// - More methodical coloring
/// - Uses undo feature
/// - Explores different categories
/// - May try to complete a full page
/// - Checks gallery to see work
/// - Longer attention span than young child
class OlderChildAgent: UITestAgent {

    init(app: XCUIApplication) {
        super.init(persona: .olderChild, app: app)
    }

    override func runTestScenario() throws -> PersonaTestResult {
        print("👧 Starting Older Child Test Scenario...")

        do {
            // Step 1: Browse categories thoughtfully
            try browseCategories()

            // Step 2: Select a challenging page
            try selectChallengingPage()

            // Step 3: Color methodically
            try colorMethodically()

            // Step 4: Use undo/clear features
            try testUndoFeature()

            // Step 5: Check gallery and admire work
            try reviewGallery()

            // Step 6: Try a different page
            try tryAnotherPage()

            return buildResult(passed: true)

        } catch {
            return buildResult(passed: false, failureReason: error.localizedDescription)
        }
    }

    // MARK: - Older Child Behaviors

    private func browseCategories() throws {
        navigateToHome()
        takeScreenshot(name: "home_browse")

        // Scroll through categories to find interesting one
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
            wait(for: 0.5)
            scrollView.swipeDown()
            wait(for: 0.5)
        }

        logAction(.swipe, target: "Browsing categories")
    }

    private func selectChallengingPage() throws {
        // Older kids like dinosaurs or ocean
        let category = persona.preferredCategories.first ?? "Dinosaurs"
        selectCategory(category)

        guard verifyScreenExists(category) else {
            throw TestError.navigationFailed("Could not open \(category)")
        }

        takeScreenshot(name: "category_view")

        // Pick a specific page (not random)
        wait(for: 1.0)

        // Try to find a page with a cool name
        let pageNames = ["T-Rex", "Shark", "Dolphin", "Volcano", "Forest"]
        for pageName in pageNames {
            let page = app.staticTexts[pageName]
            if page.exists {
                page.tap()
                wait(for: persona.tapSpeed.delay)
                logAction(.tap, target: "Selected page: \(pageName)")
                break
            }
        }

        // Fallback: tap first available page
        let pages = app.scrollViews.buttons
        if pages.count > 0 {
            pages.element(boundBy: 0).tap()
            wait(for: persona.tapSpeed.delay)
        }
    }

    private func colorMethodically() throws {
        let canvas = app.images.firstMatch
        guard canvas.waitForExistence(timeout: 3) else {
            throw TestError.elementNotFound("Canvas")
        }

        takeScreenshot(name: "canvas_start")

        // Methodical coloring: select color, then fill multiple regions
        let colorSequence = [0, 2, 4, 6, 1, 3, 5]  // Strategic color selection

        for (index, colorIndex) in colorSequence.enumerated() {
            selectColor(at: colorIndex)

            // Fill a few regions with same color (organized)
            let fillCount = Int.random(in: 2...4)
            for _ in 0..<fillCount {
                let x = 0.2 + CGFloat(index) * 0.1
                let y = CGFloat.random(in: 0.3...0.7)
                fillRegion(at: CGPoint(x: min(x, 0.8), y: y))
            }
        }

        takeScreenshot(name: "canvas_methodical")
        logAction(.fill, target: "Methodical coloring complete")
    }

    private func testUndoFeature() throws {
        // Older child knows about undo
        tapUndo()
        wait(for: 0.5)

        // Maybe undo again
        if Bool.random() {
            tapUndo()
            wait(for: 0.5)
        }

        takeScreenshot(name: "after_undo")

        // Continue coloring after undo
        selectRandomColor()
        let canvas = app.images.firstMatch
        if canvas.exists {
            tapRandomLocation(in: canvas)
            tapRandomLocation(in: canvas)
        }

        logAction(.undo, target: "Tested undo feature")
    }

    private func reviewGallery() throws {
        // Go check gallery to see saved work
        navigateToGallery()
        wait(for: 2.0)

        takeScreenshot(name: "gallery_review")

        // Scroll through gallery
        let galleryScroll = app.scrollViews.firstMatch
        if galleryScroll.exists {
            galleryScroll.swipeUp()
            wait(for: 0.5)
        }

        logAction(.navigate, target: "Reviewing gallery")
    }

    private func tryAnotherPage() throws {
        // Go back and try another category
        navigateToHome()

        let anotherCategory = persona.preferredCategories.last ?? "Nature"
        selectCategory(anotherCategory)

        wait(for: 1.0)

        // Quick color session
        let pages = app.scrollViews.buttons
        if pages.count > 0 {
            pages.element(boundBy: 0).tap()
            wait(for: persona.tapSpeed.delay)
        }

        let canvas = app.images.firstMatch
        if canvas.waitForExistence(timeout: 2) {
            selectColor(at: 3)
            tapRandomLocation(in: canvas)
            tapRandomLocation(in: canvas)
            selectColor(at: 7)
            tapRandomLocation(in: canvas)
        }

        takeScreenshot(name: "second_page")
        logAction(.fill, target: "Colored another page")
    }
}
