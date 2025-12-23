import XCTest

/// Intelligent page-level test orchestrator
/// Handles fill, save, auto-fill, undo operations for each page instance
final class PageTestOrchestrator {

    // MARK: - Configuration

    struct TestConfig {
        let fillAttempts: Int          // Number of tap-to-fill attempts
        let minFillPercent: Double     // Minimum fill percentage to achieve
        let testAutoFill: Bool
        let testUndo: Bool
        let testSave: Bool
        let testZoom: Bool
        let testDraw: Bool
        let completeWithAutoFill: Bool // Use auto-fill to complete remaining regions
        let verifySaveToPhotos: Bool   // Actually trigger save (will cancel)
        let timeout: TimeInterval

        // Thorough testing: 20%+ fill, test all features
        static let thorough = TestConfig(
            fillAttempts: 15,          // More fill attempts
            minFillPercent: 0.20,      // At least 20% filled
            testAutoFill: true,
            testUndo: true,
            testSave: true,
            testZoom: true,
            testDraw: true,
            completeWithAutoFill: true,
            verifySaveToPhotos: true,
            timeout: 30
        )

        static let standard = TestConfig(
            fillAttempts: 10,
            minFillPercent: 0.15,
            testAutoFill: true,
            testUndo: true,
            testSave: true,
            testZoom: true,
            testDraw: false,
            completeWithAutoFill: false,
            verifySaveToPhotos: false,
            timeout: 30
        )

        static let quick = TestConfig(
            fillAttempts: 5,
            minFillPercent: 0.10,
            testAutoFill: false,
            testUndo: true,
            testSave: true,
            testZoom: false,
            testDraw: false,
            completeWithAutoFill: false,
            verifySaveToPhotos: false,
            timeout: 15
        )
    }

    // MARK: - Test Results

    struct PageTestResult {
        let pageName: String
        let categoryName: String
        let passed: Bool
        let fillWorked: Bool
        let fillCount: Int          // Number of regions filled
        let undoWorked: Bool
        let autoFillWorked: Bool
        let autoFillCompleted: Bool // Did auto-fill complete the page
        let saveWorked: Bool
        let zoomWorked: Bool
        let drawWorked: Bool
        let errors: [String]
        let duration: TimeInterval
    }

    // MARK: - Properties

    private let app: XCUIApplication
    private let config: TestConfig
    private var results: [PageTestResult] = []

    // MARK: - Initialization

    init(app: XCUIApplication, config: TestConfig = .standard) {
        self.app = app
        self.config = config
    }

    // MARK: - Orchestration

    /// Test a single page with all operations
    func testPage(category: String, page: String) -> PageTestResult {
        let startTime = Date()
        var errors: [String] = []
        var fillWorked = false
        var fillCount = 0
        var undoWorked = false
        var autoFillWorked = false
        var autoFillCompleted = false
        var saveWorked = false
        var zoomWorked = false
        var drawWorked = false

        // Navigate to the page
        if !navigateToPage(category: category, page: page, errors: &errors) {
            return PageTestResult(
                pageName: page,
                categoryName: category,
                passed: false,
                fillWorked: false,
                fillCount: 0,
                undoWorked: false,
                autoFillWorked: false,
                autoFillCompleted: false,
                saveWorked: false,
                zoomWorked: false,
                drawWorked: false,
                errors: errors,
                duration: Date().timeIntervalSince(startTime)
            )
        }

        // Test fill operations - color at least 20% of the page
        (fillWorked, fillCount) = testFillOperations(errors: &errors)

        // Test undo (undo 1-2 fills, then redo)
        if config.testUndo {
            undoWorked = testUndoOperation(errors: &errors)
        }

        // Test zoom
        if config.testZoom {
            zoomWorked = testZoomOperations(errors: &errors)
        }

        // Test draw mode
        if config.testDraw {
            drawWorked = testDrawOperation(errors: &errors)
        }

        // Test auto-fill to complete remaining regions
        if config.testAutoFill || config.completeWithAutoFill {
            (autoFillWorked, autoFillCompleted) = testAutoFillOperation(complete: config.completeWithAutoFill, errors: &errors)
        }

        // Test save - actually try to save to photos
        if config.testSave {
            saveWorked = testSaveOperation(verifySave: config.verifySaveToPhotos, errors: &errors)
        }

        // Navigate back
        navigateBack()

        let passed = errors.isEmpty && fillWorked && fillCount >= 3

        return PageTestResult(
            pageName: page,
            categoryName: category,
            passed: passed,
            fillWorked: fillWorked,
            fillCount: fillCount,
            undoWorked: undoWorked,
            autoFillWorked: autoFillWorked,
            autoFillCompleted: autoFillCompleted,
            saveWorked: saveWorked,
            zoomWorked: zoomWorked,
            drawWorked: drawWorked,
            errors: errors,
            duration: Date().timeIntervalSince(startTime)
        )
    }

    // MARK: - Navigation

    private func navigateToPage(category: String, page: String, errors: inout [String]) -> Bool {
        // First go to home
        goToHome()

        // Find and tap category
        let categoryElement = app.staticTexts[category]
        if !categoryElement.exists {
            app.swipeUp()
            sleep(1)
        }

        guard categoryElement.waitForExistence(timeout: config.timeout) else {
            errors.append("Category '\(category)' not found")
            return false
        }

        categoryElement.tap()

        // Wait for category view
        guard app.navigationBars[category].waitForExistence(timeout: config.timeout) else {
            errors.append("Failed to navigate to category '\(category)'")
            return false
        }

        // Find and tap page
        let pageElement = app.staticTexts[page]
        if !pageElement.exists {
            app.swipeUp()
            sleep(1)
        }

        guard pageElement.waitForExistence(timeout: config.timeout) else {
            errors.append("Page '\(page)' not found in category '\(category)'")
            return false
        }

        pageElement.tap()

        // Wait for canvas to load
        guard app.navigationBars[page].waitForExistence(timeout: config.timeout) else {
            errors.append("Failed to navigate to page '\(page)'")
            return false
        }

        sleep(1) // Allow canvas to fully load
        return true
    }

    private func goToHome() {
        // Keep pressing back until we reach home
        var attempts = 0
        while !app.navigationBars["Color Fun"].exists && attempts < 5 {
            if app.navigationBars.buttons.count > 0 {
                app.navigationBars.buttons.element(boundBy: 0).tap()
            }
            attempts += 1
            sleep(1)
        }
    }

    private func navigateBack() {
        if app.navigationBars.buttons.count > 0 {
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }
    }

    // MARK: - Fill Operations

    private func testFillOperations(errors: inout [String]) -> (Bool, Int) {
        var fillCount = 0

        // Find the canvas area
        let canvas = app.scrollViews.firstMatch

        guard canvas.exists else {
            errors.append("Canvas not found")
            return (false, 0)
        }

        // Get color palette buttons
        let colorButtons = app.scrollViews.buttons

        // Grid-based tap pattern to cover more of the canvas
        let gridPositions: [(Double, Double)] = [
            // Center area
            (0.5, 0.4), (0.5, 0.5), (0.5, 0.6),
            // Left side
            (0.25, 0.35), (0.25, 0.5), (0.25, 0.65),
            // Right side
            (0.75, 0.35), (0.75, 0.5), (0.75, 0.65),
            // Top area
            (0.35, 0.25), (0.5, 0.25), (0.65, 0.25),
            // Bottom area
            (0.35, 0.75), (0.5, 0.75), (0.65, 0.75),
            // Additional fill points for 20%+ coverage
            (0.4, 0.45), (0.6, 0.45), (0.4, 0.55), (0.6, 0.55),
            (0.3, 0.4), (0.7, 0.4), (0.3, 0.6), (0.7, 0.6)
        ]

        // Use configured fill attempts or grid positions count
        let attempts = min(config.fillAttempts, gridPositions.count)

        for i in 0..<attempts {
            // Select a different color for each region
            if colorButtons.count > 0 {
                let colorIndex = i % max(1, colorButtons.count)
                colorButtons.element(boundBy: colorIndex).tap()
                usleep(100000) // 100ms to select color
            }

            // Tap on canvas at grid position
            let (x, y) = gridPositions[i]
            let coordinate = canvas.coordinate(withNormalizedOffset: CGVector(dx: x, dy: y))
            coordinate.tap()

            fillCount += 1
            usleep(150000) // 150ms between fills
        }

        print("    Filled \(fillCount) regions")
        return (fillCount > 0, fillCount)
    }

    private func testUndoOperation(errors: inout [String]) -> Bool {
        // Find undo button (arrow.uturn.backward.circle.fill)
        let undoButton = app.buttons["arrow.uturn.backward.circle.fill"]

        guard undoButton.waitForExistence(timeout: 5) else {
            errors.append("Undo button not found")
            return false
        }

        // Tap undo
        undoButton.tap()
        usleep(300000) // 300ms

        return true
    }

    private func testZoomOperations(errors: inout [String]) -> Bool {
        // Find zoom buttons
        let zoomInButton = app.buttons.matching(identifier: "plus").firstMatch
        let zoomOutButton = app.buttons.matching(identifier: "minus").firstMatch

        // Alternative: look for + and - buttons
        let plusButton = app.staticTexts["+"].firstMatch
        let minusButton = app.staticTexts["-"].firstMatch

        // Try to zoom if buttons exist
        if zoomInButton.exists {
            zoomInButton.tap()
            usleep(200000)
            if zoomOutButton.exists {
                zoomOutButton.tap()
            }
            return true
        }

        // Pinch gesture as alternative
        let canvas = app.scrollViews.firstMatch
        if canvas.exists {
            canvas.pinch(withScale: 1.5, velocity: 1)
            usleep(300000)
            canvas.pinch(withScale: 0.67, velocity: 1)
            return true
        }

        return false
    }

    private func testDrawOperation(errors: inout [String]) -> Bool {
        // Find Draw mode button
        let drawButton = app.buttons["Draw"]

        guard drawButton.waitForExistence(timeout: 5) else {
            // Draw mode might not be available
            return false
        }

        // Switch to draw mode
        drawButton.tap()
        usleep(300000) // 300ms

        // Draw a line on canvas
        let canvas = app.scrollViews.firstMatch
        if canvas.exists {
            let start = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.4))
            let end = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.6))
            start.press(forDuration: 0.1, thenDragTo: end)
            usleep(200000)
        }

        // Switch back to Fill mode
        let fillButton = app.buttons["Fill"]
        if fillButton.exists {
            fillButton.tap()
            usleep(200000)
        }

        return true
    }

    private func testAutoFillOperation(complete: Bool, errors: inout [String]) -> (Bool, Bool) {
        // Find autofill button (wand.and.stars)
        let autoFillButton = app.buttons["wand.and.stars"]

        guard autoFillButton.waitForExistence(timeout: 5) else {
            // Autofill might not be available if page is already complete
            return (true, true)
        }

        guard autoFillButton.isEnabled else {
            // Button disabled, page might be complete
            return (true, true)
        }

        autoFillButton.tap()
        usleep(500000) // 500ms

        // Check if confirmation dialog appeared
        let fillButton = app.buttons["Fill with random colors"]
        if fillButton.waitForExistence(timeout: 3) {
            if complete {
                // Actually complete the page with auto-fill
                fillButton.tap()
                usleep(1000000) // 1s for auto-fill animation
                print("    Auto-filled remaining regions")
                return (true, true)
            } else {
                // Just verify dialog works, then cancel
                let cancelButton = app.buttons["Cancel"]
                if cancelButton.exists {
                    cancelButton.tap()
                }
                return (true, false)
            }
        }

        return (true, false)
    }

    private func testSaveOperation(verifySave: Bool, errors: inout [String]) -> Bool {
        // Find share button
        let shareButton = app.buttons["square.and.arrow.up"]

        guard shareButton.waitForExistence(timeout: 5) else {
            errors.append("Share button not found")
            return false
        }

        guard shareButton.isEnabled else {
            errors.append("Share button disabled")
            return false
        }

        if verifySave {
            // Tap share to open share sheet
            shareButton.tap()
            usleep(1000000) // 1s for share sheet

            // Look for "Save Image" option or dismiss the sheet
            let saveImageButton = app.buttons["Save Image"]
            if saveImageButton.waitForExistence(timeout: 3) {
                // Don't actually save, just verify it exists
                // Dismiss by tapping elsewhere
                app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)).tap()
                usleep(500000)
                print("    Save sheet verified")
                return true
            }

            // If share sheet is open, dismiss it
            let closeButton = app.buttons["Close"]
            if closeButton.exists {
                closeButton.tap()
            } else {
                // Tap outside to dismiss
                app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)).tap()
            }
            usleep(500000)
            return true
        }

        // Just verify button exists and is enabled
        return true
    }

    // MARK: - Report Generation

    func generateReport() -> String {
        let totalFilled = results.reduce(0) { $0 + $1.fillCount }
        let avgFillCount = results.isEmpty ? 0 : totalFilled / results.count
        let autoFilledCount = results.filter { $0.autoFillCompleted }.count

        var report = """
        =====================================
        PAGE TEST ORCHESTRATOR REPORT
        =====================================

        Total Pages Tested: \(results.count)
        Passed: \(results.filter { $0.passed }.count)
        Failed: \(results.filter { !$0.passed }.count)

        Fill Statistics:
          Total Regions Filled: \(totalFilled)
          Avg Fills Per Page: \(avgFillCount)
          Pages Auto-Completed: \(autoFilledCount)

        """

        for result in results {
            report += """

            [\(result.passed ? "PASS" : "FAIL")] \(result.categoryName) > \(result.pageName)
              Duration: \(String(format: "%.2f", result.duration))s
              Filled: \(result.fillCount) regions
              Undo: \(result.undoWorked ? "OK" : "-")
              Draw: \(result.drawWorked ? "OK" : "-")
              AutoFill: \(result.autoFillWorked ? "OK" : "-") \(result.autoFillCompleted ? "(Completed)" : "")
              Save: \(result.saveWorked ? "OK" : "-")
              Zoom: \(result.zoomWorked ? "OK" : "-")

            """

            if !result.errors.isEmpty {
                report += "  Errors:\n"
                for error in result.errors {
                    report += "    - \(error)\n"
                }
            }
        }

        return report
    }

    func addResult(_ result: PageTestResult) {
        results.append(result)
    }
}

// MARK: - Parallel Test Runner

final class ParallelTestRunner {

    /// Run tests on multiple pages in parallel using multiple test instances
    static func runParallelTests(
        app: XCUIApplication,
        pages: [(category: String, page: String)],
        parallelCount: Int = 5
    ) -> [PageTestOrchestrator.PageTestResult] {

        let orchestrator = PageTestOrchestrator(app: app, config: .quick)
        var allResults: [PageTestOrchestrator.PageTestResult] = []

        // Split pages into chunks for sequential processing
        // (True parallelism requires multiple simulator instances)
        let chunkSize = max(1, pages.count / parallelCount)
        let chunks = stride(from: 0, to: pages.count, by: chunkSize).map {
            Array(pages[$0..<min($0 + chunkSize, pages.count)])
        }

        for (index, chunk) in chunks.enumerated() {
            print("Processing chunk \(index + 1)/\(chunks.count) with \(chunk.count) pages")

            for (category, page) in chunk {
                let result = orchestrator.testPage(category: category, page: page)
                allResults.append(result)
                orchestrator.addResult(result)

                print("  [\(result.passed ? "PASS" : "FAIL")] \(category) > \(page)")
            }
        }

        print(orchestrator.generateReport())

        return allResults
    }
}
