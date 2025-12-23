import XCTest

// MARK: - Young Child Agent (Ages 3-5)
/// Simulates a young child's interaction with the app:
/// - Random tapping
/// - Short attention span
/// - Prefers simple categories (Animals, Vehicles)
/// - May tap multiple colors quickly
/// - Doesn't use advanced features
class YoungChildAgent: UITestAgent {

    init(app: XCUIApplication) {
        super.init(persona: .youngChild, app: app)
    }

    override func runTestScenario() throws -> PersonaTestResult {
        print("🧒 Starting Young Child Test Scenario...")

        do {
            // Step 1: Look around home screen (curious tapping)
            try exploreHomeScreen()

            // Step 2: Pick a favorite category
            try selectFavoriteCategory()

            // Step 3: Color a page with random taps
            try colorWithRandomTaps()

            // Step 4: Maybe get distracted and go to gallery
            try checkGalleryBriefly()

            // Step 5: Go back to coloring
            try returnToColoring()

            return buildResult(passed: true)

        } catch {
            return buildResult(passed: false, failureReason: error.localizedDescription)
        }
    }

    // MARK: - Young Child Behaviors

    private func exploreHomeScreen() throws {
        navigateToHome()
        takeScreenshot(name: "home_explore")

        // Young child looks at the screen for a moment
        wait(for: 1.0)

        // Tap a few things curiously
        let categories = app.scrollViews.firstMatch
        if categories.exists {
            tapRandomLocation(in: categories)
            wait(for: 0.5)
        }

        logAction(.wait, target: "Looking at home screen")
    }

    private func selectFavoriteCategory() throws {
        // Young kids love Animals
        let favoriteCategory = persona.preferredCategories.randomElement() ?? "Animals"
        selectCategory(favoriteCategory)

        guard verifyScreenExists(favoriteCategory) else {
            throw TestError.navigationFailed("Could not open \(favoriteCategory)")
        }

        takeScreenshot(name: "category_selected")

        // Pick a page (tap somewhat randomly)
        wait(for: 1.0)
        let pages = app.scrollViews.firstMatch
        if pages.exists {
            tapRandomLocation(in: pages)
        }

        wait(for: persona.tapSpeed.delay)
    }

    private func colorWithRandomTaps() throws {
        // Young child colors randomly
        let canvas = app.images.firstMatch
        guard canvas.waitForExistence(timeout: 3) else {
            throw TestError.elementNotFound("Canvas")
        }

        takeScreenshot(name: "canvas_start")

        // Random coloring session - short attention span
        let tapCount = Int.random(in: 5...10)

        for i in 0..<tapCount {
            // Sometimes change color
            if Int.random(in: 0...2) == 0 {
                selectRandomColor()
            }

            // Tap random location
            tapRandomLocation(in: canvas)

            // Young child is fast but imprecise
            wait(for: Double.random(in: 0.3...0.8))

            logAction(.fill, target: "Random tap \(i + 1)")
        }

        takeScreenshot(name: "canvas_colored")
    }

    private func checkGalleryBriefly() throws {
        // Gets distracted, checks gallery
        navigateToGallery()

        wait(for: 1.5)
        takeScreenshot(name: "gallery_peek")

        // Doesn't stay long
        logAction(.wait, target: "Briefly checking gallery")
    }

    private func returnToColoring() throws {
        // Goes back to home
        navigateToHome()

        // Might tap something else
        let anotherCategory = persona.preferredCategories.randomElement() ?? "Vehicles"
        selectCategory(anotherCategory)

        wait(for: 2.0)
        takeScreenshot(name: "final_screen")
    }
}

// MARK: - Test Error
enum TestError: Error, LocalizedError {
    case navigationFailed(String)
    case elementNotFound(String)
    case actionFailed(String)

    var errorDescription: String? {
        switch self {
        case .navigationFailed(let detail): return "Navigation failed: \(detail)"
        case .elementNotFound(let element): return "Element not found: \(element)"
        case .actionFailed(let action): return "Action failed: \(action)"
        }
    }
}
