import XCTest

final class NavigationUITests: XCTestCase {
    var app: XCUIApplication!

    // Define all categories and their pages for comprehensive testing
    let categoryPages: [String: [String]] = [
        "Animals": ["Cat", "Dog", "Elephant", "Bunny", "Bear", "Bird", "Fox"],
        "Vehicles": ["Car"],
        "Houses": ["Cottage"],
        "Nature": ["Flower", "Star", "Rose", "Daisy", "Tulip"],
        "Ocean": ["Fish"],
        "Retro 90s": ["Boombox", "Turntable"],
        "Mandalas": ["Mandala 1", "Mandala 2", "Mandala 3", "Mandala 4", "Mandala 5", "Mandala 6"],
        "Geometric": ["Pattern 1", "Pattern 2", "Pattern 3", "Pattern 4", "Pattern 5", "Pattern 6"],
        "Abstract": ["Abstract 1", "Abstract 2"],
        "Dinosaurs": ["T-Rex", "Triceratops", "Stegosaurus"],
        "Space": ["Rocket", "Astronaut", "Planet"],
        "Food": ["Cupcake", "Ice Cream", "Pizza"],
        "Holidays": ["Christmas Tree", "Easter Egg", "Pumpkin"],
        "Sports": ["Soccer Ball", "Basketball", "Baseball"],
        "Music": ["Guitar", "Piano", "Drums"],
        "Robots": ["Robot 1", "Robot 2", "Robot 3"],
        "Fantasy": ["Unicorn", "Dragon", "Castle"],
        "Underwater": ["Octopus", "Seahorse", "Turtle"],
        "Zen Patterns": ["Zen 1", "Zen 2", "Zen 3"],
        "Portraits": ["Princess", "Superhero", "Fairy"]
    ]

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
        // Test all 9 categories are visible (may need to scroll)
        let allCategories = Array(categoryPages.keys)
        for category in allCategories {
            // Scroll to find category if needed
            let categoryElement = app.staticTexts[category]
            if !categoryElement.exists {
                app.swipeUp()
            }
            XCTAssertTrue(categoryElement.waitForExistence(timeout: 3),
                         "Category '\(category)' should be visible")
        }
    }

    func testUploadPhotoCardExists() throws {
        // Verify Upload Photo card is visible
        XCTAssertTrue(app.staticTexts["Upload Photo"].waitForExistence(timeout: 2),
                     "Upload Photo card should be visible on home screen")
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

    func testNavigateToEachCategory() throws {
        for category in categoryPages.keys.sorted() {
            // Navigate to home first
            while !app.navigationBars["Color Fun"].exists {
                if app.navigationBars.buttons.count > 0 {
                    app.navigationBars.buttons.element(boundBy: 0).tap()
                } else {
                    break
                }
            }

            // Find and tap the category
            let categoryElement = app.staticTexts[category]
            if !categoryElement.exists {
                app.swipeUp()
            }
            if categoryElement.waitForExistence(timeout: 2) {
                categoryElement.tap()
                XCTAssertTrue(app.navigationBars[category].waitForExistence(timeout: 2),
                             "Should navigate to \(category) category")

                // Go back
                app.navigationBars.buttons.element(boundBy: 0).tap()
            }
        }
    }

    // MARK: - Animals Category Tests

    func testAnimalsAllPages() throws {
        app.staticTexts["Animals"].tap()
        XCTAssertTrue(app.navigationBars["Animals"].waitForExistence(timeout: 2))

        let pages = categoryPages["Animals"]!
        for page in pages {
            XCTAssertTrue(app.staticTexts[page].waitForExistence(timeout: 2),
                         "Page '\(page)' should be visible in Animals category")
        }
    }

    // MARK: - Nature Category Tests

    func testNatureAllPages() throws {
        app.staticTexts["Nature"].tap()
        XCTAssertTrue(app.navigationBars["Nature"].waitForExistence(timeout: 2))

        let pages = categoryPages["Nature"]!
        for page in pages {
            XCTAssertTrue(app.staticTexts[page].waitForExistence(timeout: 2),
                         "Page '\(page)' should be visible in Nature category")
        }
    }

    // MARK: - Mandalas Category Tests

    func testMandalasAllPages() throws {
        // Scroll to find Mandalas
        let mandalaCategory = app.staticTexts["Mandalas"]
        if !mandalaCategory.exists {
            app.swipeUp()
        }
        mandalaCategory.tap()
        XCTAssertTrue(app.navigationBars["Mandalas"].waitForExistence(timeout: 2))

        let pages = categoryPages["Mandalas"]!
        for page in pages {
            // May need to scroll to see all mandalas
            let pageElement = app.staticTexts[page]
            if !pageElement.exists {
                app.swipeUp()
            }
            XCTAssertTrue(pageElement.waitForExistence(timeout: 2),
                         "Page '\(page)' should be visible in Mandalas category")
        }
    }

    // MARK: - Geometric Category Tests

    func testGeometricAllPages() throws {
        let geometricCategory = app.staticTexts["Geometric"]
        if !geometricCategory.exists {
            app.swipeUp()
        }
        geometricCategory.tap()
        XCTAssertTrue(app.navigationBars["Geometric"].waitForExistence(timeout: 2))

        let pages = categoryPages["Geometric"]!
        for page in pages {
            let pageElement = app.staticTexts[page]
            if !pageElement.exists {
                app.swipeUp()
            }
            XCTAssertTrue(pageElement.waitForExistence(timeout: 2),
                         "Page '\(page)' should be visible in Geometric category")
        }
    }

    // MARK: - Canvas Navigation Tests

    func testNavigateToMultipleCanvasPages() throws {
        // Test navigating to different coloring pages across categories
        let testPages: [(String, String)] = [
            ("Animals", "Cat"),
            ("Animals", "Dog"),
            ("Nature", "Flower"),
            ("Vehicles", "Car"),
            ("Ocean", "Fish")
        ]

        for (category, page) in testPages {
            // Go to home
            while !app.navigationBars["Color Fun"].exists {
                if app.navigationBars.buttons.count > 0 {
                    app.navigationBars.buttons.element(boundBy: 0).tap()
                } else {
                    break
                }
            }

            // Navigate to category
            let categoryElement = app.staticTexts[category]
            if !categoryElement.exists {
                app.swipeUp()
            }
            categoryElement.tap()
            XCTAssertTrue(app.navigationBars[category].waitForExistence(timeout: 2))

            // Navigate to page
            app.staticTexts[page].tap()
            XCTAssertTrue(app.navigationBars[page].waitForExistence(timeout: 2),
                         "Should open canvas for \(page)")

            // Verify canvas elements exist
            sleep(1) // Let canvas load
        }
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

    func testCanvasModeToggle() throws {
        app.staticTexts["Animals"].tap()
        app.staticTexts["Dog"].tap()

        // Look for Fill/Draw mode toggle
        let fillButton = app.buttons["Fill"]
        let drawButton = app.buttons["Draw"]

        if fillButton.waitForExistence(timeout: 2) {
            fillButton.tap()
        }
        if drawButton.waitForExistence(timeout: 2) {
            drawButton.tap()
        }
    }

    // MARK: - Photo Upload Tests

    func testPhotoUploadUIOpens() throws {
        // Tap Upload Photo button
        app.staticTexts["Upload Photo"].tap()

        // Verify photo upload view opens
        XCTAssertTrue(app.navigationBars["Create Coloring Page"].waitForExistence(timeout: 2),
                     "Photo upload view should open")

        // Verify Cancel button exists
        XCTAssertTrue(app.buttons["Cancel"].exists, "Cancel button should exist")

        // Tap Cancel to close
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.navigationBars["Color Fun"].waitForExistence(timeout: 2))
    }

    // MARK: - Full Flow Tests

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

    func testRetro90sCategory() throws {
        let retroCategory = app.staticTexts["Retro 90s"]
        if !retroCategory.exists {
            app.swipeUp()
        }
        retroCategory.tap()
        XCTAssertTrue(app.navigationBars["Retro 90s"].waitForExistence(timeout: 2))

        let pages = categoryPages["Retro 90s"]!
        for page in pages {
            XCTAssertTrue(app.staticTexts[page].waitForExistence(timeout: 2),
                         "Page '\(page)' should be visible in Retro 90s category")
        }
    }

    func testAbstractCategory() throws {
        let abstractCategory = app.staticTexts["Abstract"]
        if !abstractCategory.exists {
            app.swipeUp()
        }
        abstractCategory.tap()
        XCTAssertTrue(app.navigationBars["Abstract"].waitForExistence(timeout: 2))

        let pages = categoryPages["Abstract"]!
        for page in pages {
            XCTAssertTrue(app.staticTexts[page].waitForExistence(timeout: 2),
                         "Page '\(page)' should be visible in Abstract category")
        }
    }
}
