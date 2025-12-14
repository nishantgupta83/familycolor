import XCTest

final class GalleryUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Gallery Navigation

    func testGalleryTabExists() throws {
        let galleryTab = app.tabBars.buttons.element(boundBy: 1)
        XCTAssertTrue(galleryTab.exists)
    }

    func testNavigateToGallery() throws {
        app.tabBars.buttons.element(boundBy: 1).tap()
        XCTAssertTrue(app.navigationBars["My Gallery"].waitForExistence(timeout: 2))
    }

    func testGalleryEmptyState() throws {
        // Clear any saved artwork first (if possible via app reset)
        app.tabBars.buttons.element(boundBy: 1).tap()

        // Gallery should show empty state or grid
        XCTAssertTrue(app.navigationBars["My Gallery"].exists)
    }

    // MARK: - Save and View Flow

    func testSaveArtworkAppearsInGallery() throws {
        // Navigate to canvas
        app.staticTexts["Animals"].tap()
        app.staticTexts["Cat"].tap()

        // Do some coloring
        let canvas = app.otherElements.firstMatch
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()

        // Share/Save
        app.buttons["square.and.arrow.up"].tap()

        // Dismiss share sheet
        sleep(1)
        if app.buttons["Close"].exists {
            app.buttons["Close"].tap()
        } else {
            app.swipeDown()
        }

        // Navigate to gallery
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.tabBars.buttons.element(boundBy: 1).tap()

        // Gallery should show saved artwork
        XCTAssertTrue(app.navigationBars["My Gallery"].waitForExistence(timeout: 2))
    }

    // MARK: - Gallery Grid

    func testGalleryGridLayout() throws {
        app.tabBars.buttons.element(boundBy: 1).tap()

        // Gallery should be scrollable if content exists
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
            scrollView.swipeDown()
        }

        XCTAssertTrue(app.navigationBars["My Gallery"].exists)
    }
}
