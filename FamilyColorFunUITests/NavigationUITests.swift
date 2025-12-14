import XCTest

final class NavigationUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Home Screen Tests

    func testHomeScreenLoads() throws {
        XCTAssertTrue(app.navigationBars["Color Fun"].exists)
        XCTAssertTrue(app.tabBars.buttons.count >= 2)
    }

    func testAllCategoriesDisplayed() throws {
        let categories = ["Animals", "Dinosaurs", "Vehicles", "Houses", "Nature", "Ocean"]
        for category in categories {
            XCTAssertTrue(app.staticTexts[category].waitForExistence(timeout: 2),
                         "Category '\(category)' should be visible")
        }
    }

    func testTabBarNavigation() throws {
        // Tap Gallery tab
        app.tabBars.buttons.element(boundBy: 1).tap()
        XCTAssertTrue(app.navigationBars["My Gallery"].waitForExistence(timeout: 2))

        // Tap Home tab
        app.tabBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.navigationBars["Color Fun"].waitForExistence(timeout: 2))
    }

    // MARK: - Category Navigation Tests

    func testNavigateToCategory() throws {
        app.staticTexts["Animals"].tap()
        XCTAssertTrue(app.navigationBars["Animals"].waitForExistence(timeout: 2))
    }

    func testCategoryShowsPages() throws {
        app.staticTexts["Animals"].tap()

        // Verify page names are visible
        let pageNames = ["Cat", "Dog", "Elephant", "Lion", "Rabbit", "Bird"]
        for page in pageNames {
            XCTAssertTrue(app.staticTexts[page].waitForExistence(timeout: 2),
                         "Page '\(page)' should be visible in Animals category")
        }
    }

    func testBackNavigationFromCategory() throws {
        app.staticTexts["Dinosaurs"].tap()
        XCTAssertTrue(app.navigationBars["Dinosaurs"].waitForExistence(timeout: 2))

        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.navigationBars["Color Fun"].waitForExistence(timeout: 2))
    }

    // MARK: - Canvas Navigation Tests

    func testNavigateToCanvas() throws {
        app.staticTexts["Vehicles"].tap()
        app.staticTexts["Car"].tap()

        // Verify canvas loaded
        XCTAssertTrue(app.navigationBars["Car"].waitForExistence(timeout: 2))
    }

    func testCanvasHasRequiredElements() throws {
        app.staticTexts["Animals"].tap()
        app.staticTexts["Cat"].tap()

        // Check for share button
        XCTAssertTrue(app.buttons["square.and.arrow.up"].waitForExistence(timeout: 2))

        // Check for undo button
        XCTAssertTrue(app.buttons["arrow.uturn.backward.circle.fill"].waitForExistence(timeout: 2))

        // Check for trash button
        XCTAssertTrue(app.buttons["trash.circle.fill"].waitForExistence(timeout: 2))
    }

    func testFullNavigationFlow() throws {
        // Home -> Category -> Canvas -> Back -> Back -> Home
        app.staticTexts["Ocean"].tap()
        XCTAssertTrue(app.navigationBars["Ocean"].waitForExistence(timeout: 2))

        app.staticTexts["Fish"].tap()
        XCTAssertTrue(app.navigationBars["Fish"].waitForExistence(timeout: 2))

        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.navigationBars["Ocean"].waitForExistence(timeout: 2))

        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.navigationBars["Color Fun"].waitForExistence(timeout: 2))
    }
}
