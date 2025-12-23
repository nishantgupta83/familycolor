import XCTest

// MARK: - UI Test Agent Protocol
protocol UITestAgentProtocol {
    var persona: UserPersona { get }
    var app: XCUIApplication { get }
    var session: TestSession { get set }

    func runTestScenario() throws -> PersonaTestResult
    func navigateToHome()
    func navigateToGallery()
    func navigateToSettings()
    func selectCategory(_ name: String)
    func selectPage(_ name: String)
    func fillRegion(at point: CGPoint)
    func selectColor(at index: Int)
}

// MARK: - Base UI Test Agent
class UITestAgent: UITestAgentProtocol {
    let persona: UserPersona
    let app: XCUIApplication
    var session: TestSession
    private var screensVisited: [String] = []

    init(persona: UserPersona, app: XCUIApplication) {
        self.persona = persona
        self.app = app
        self.session = TestSession(persona: persona)
    }

    // MARK: - Main Test Runner
    func runTestScenario() throws -> PersonaTestResult {
        fatalError("Subclasses must override runTestScenario()")
    }

    // MARK: - Navigation Helpers
    func navigateToHome() {
        let homeTab = app.tabBars.buttons.element(boundBy: 0)
        if homeTab.exists {
            homeTab.tap()
            wait(for: persona.tapSpeed.delay)
            logAction(.navigate, target: "Home")
            screensVisited.append("Home")
        }
    }

    func navigateToGallery() {
        let galleryTab = app.tabBars.buttons.element(boundBy: 1)
        if galleryTab.exists {
            galleryTab.tap()
            wait(for: persona.tapSpeed.delay)
            logAction(.navigate, target: "Gallery")
            screensVisited.append("Gallery")
        }
    }

    func navigateToSettings() {
        // Open settings from toolbar
        let settingsButton = app.buttons["gearshape"]
        if settingsButton.exists {
            settingsButton.tap()
            wait(for: persona.tapSpeed.delay)
            logAction(.settings, target: "Settings")
            screensVisited.append("Settings")
        }
    }

    func goBack() {
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        if backButton.exists && backButton.isHittable {
            backButton.tap()
            wait(for: persona.tapSpeed.delay)
            logAction(.navigate, target: "Back")
        }
    }

    func dismissSheet() {
        let doneButton = app.buttons["Done"]
        if doneButton.exists {
            doneButton.tap()
            wait(for: persona.tapSpeed.delay)
        }
    }

    // MARK: - Category & Page Selection
    func selectCategory(_ name: String) {
        let category = app.staticTexts[name]
        if category.waitForExistence(timeout: 3) {
            category.tap()
            wait(for: persona.tapSpeed.delay)
            logAction(.tap, target: "Category: \(name)")
            screensVisited.append(name)
        }
    }

    func selectPage(_ name: String) {
        let page = app.staticTexts[name]
        if page.waitForExistence(timeout: 3) {
            page.tap()
            wait(for: persona.tapSpeed.delay)
            logAction(.tap, target: "Page: \(name)")
            screensVisited.append("Canvas: \(name)")
        }
    }

    // MARK: - Canvas Interactions
    func fillRegion(at point: CGPoint) {
        let canvas = app.images.firstMatch
        if canvas.exists {
            canvas.coordinate(withNormalizedOffset: CGVector(dx: point.x, dy: point.y)).tap()
            wait(for: persona.tapSpeed.delay)
            logAction(.fill, target: "(\(point.x), \(point.y))")
        }
    }

    func selectColor(at index: Int) {
        // Colors are in a horizontal scroll view
        let colorButtons = app.scrollViews.buttons
        if colorButtons.count > index {
            colorButtons.element(boundBy: index).tap()
            wait(for: persona.tapSpeed.delay / 2)
            logAction(.selectColor, target: "Color \(index)")
        }
    }

    func tapUndo() {
        let undoButton = app.buttons["arrow.uturn.backward.circle.fill"]
        if undoButton.exists && undoButton.isEnabled {
            undoButton.tap()
            wait(for: persona.tapSpeed.delay)
            logAction(.undo, target: "Undo")
        }
    }

    func tapClear() {
        let clearButton = app.buttons["trash.circle.fill"]
        if clearButton.exists {
            clearButton.tap()
            wait(for: persona.tapSpeed.delay)
            logAction(.tap, target: "Clear")
        }
    }

    func tapShare() {
        let shareButton = app.buttons["square.and.arrow.up"]
        if shareButton.exists {
            shareButton.tap()
            wait(for: persona.tapSpeed.delay)
            logAction(.share, target: "Share")
        }
    }

    // MARK: - Random Actions (for child personas)
    func tapRandomLocation(in element: XCUIElement) {
        let randomX = CGFloat.random(in: 0.2...0.8)
        let randomY = CGFloat.random(in: 0.2...0.8)
        element.coordinate(withNormalizedOffset: CGVector(dx: randomX, dy: randomY)).tap()
        wait(for: persona.tapSpeed.delay)
        logAction(.tap, target: "Random: (\(randomX), \(randomY))")
    }

    func selectRandomColor() {
        let colorIndex = Int.random(in: 0..<12)
        selectColor(at: colorIndex)
    }

    // MARK: - Swipe Gestures
    func swipeOnCanvas(direction: SwipeDirection) {
        let canvas = app.images.firstMatch
        if canvas.exists {
            switch direction {
            case .left: canvas.swipeLeft()
            case .right: canvas.swipeRight()
            case .up: canvas.swipeUp()
            case .down: canvas.swipeDown()
            }
            wait(for: persona.tapSpeed.delay)
            logAction(.swipe, target: direction.rawValue)
        }
    }

    // MARK: - Verification Helpers
    func verifyScreenExists(_ screenName: String, timeout: TimeInterval = 3) -> Bool {
        return app.navigationBars[screenName].waitForExistence(timeout: timeout)
    }

    func verifyElementExists(_ identifier: String, timeout: TimeInterval = 3) -> Bool {
        return app.descendants(matching: .any)[identifier].waitForExistence(timeout: timeout)
    }

    func verifyTabBarVisible() -> Bool {
        return app.tabBars.firstMatch.exists
    }

    // MARK: - Screenshot
    func takeScreenshot(name: String) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "\(persona.rawValue)_\(name)_\(session.sessionId)"
        attachment.lifetime = .keepAlways
        session.screenshots.append(attachment.name ?? name)
    }

    // MARK: - Utility
    func wait(for seconds: TimeInterval) {
        Thread.sleep(forTimeInterval: seconds)
    }

    func logAction(_ type: ActionType, target: String, success: Bool = true, notes: String? = nil) {
        let action = UserAction(type: type, target: target, success: success, notes: notes)
        session.log(action)
    }

    // MARK: - Result Builder
    func buildResult(passed: Bool, failureReason: String? = nil) -> PersonaTestResult {
        return PersonaTestResult(
            persona: persona,
            session: session,
            passed: passed,
            failureReason: failureReason,
            duration: Date().timeIntervalSince(session.startTime),
            screensVisited: screensVisited
        )
    }
}

// MARK: - Swipe Direction
enum SwipeDirection: String {
    case left, right, up, down
}
