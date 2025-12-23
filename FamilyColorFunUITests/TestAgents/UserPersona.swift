import XCTest

// MARK: - User Persona Definition
enum UserPersona: String, CaseIterable {
    case youngChild = "Young Child (3-5)"
    case olderChild = "Older Child (6-9)"
    case parent = "Parent"

    var ageRange: ClosedRange<Int> {
        switch self {
        case .youngChild: return 3...5
        case .olderChild: return 6...9
        case .parent: return 25...45
        }
    }

    var tapSpeed: TapSpeed {
        switch self {
        case .youngChild: return .slow
        case .olderChild: return .normal
        case .parent: return .fast
        }
    }

    var attentionSpan: TimeInterval {
        switch self {
        case .youngChild: return 5.0  // Short attention, quick actions
        case .olderChild: return 15.0 // Medium attention
        case .parent: return 30.0     // Longer, purposeful actions
        }
    }

    var preferredCategories: [String] {
        switch self {
        case .youngChild: return ["Animals", "Vehicles"]
        case .olderChild: return ["Dinosaurs", "Ocean", "Nature"]
        case .parent: return ["Settings", "Gallery", "Parent Zone"]
        }
    }

    var coloringStyle: ColoringStyle {
        switch self {
        case .youngChild: return .random    // Taps everywhere
        case .olderChild: return .methodical // Colors region by region
        case .parent: return .testing       // Checks features
        }
    }
}

enum TapSpeed {
    case slow, normal, fast

    var delay: TimeInterval {
        switch self {
        case .slow: return 1.5
        case .normal: return 0.8
        case .fast: return 0.3
        }
    }
}

enum ColoringStyle {
    case random     // Taps randomly
    case methodical // Systematic coloring
    case testing    // Feature verification
}

// MARK: - Test Session
struct TestSession {
    let persona: UserPersona
    let sessionId: String
    let startTime: Date
    var actions: [UserAction] = []
    var screenshots: [String] = []

    init(persona: UserPersona) {
        self.persona = persona
        self.sessionId = UUID().uuidString.prefix(8).description
        self.startTime = Date()
    }

    mutating func log(_ action: UserAction) {
        actions.append(action)
    }
}

// MARK: - User Action Tracking
struct UserAction {
    let type: ActionType
    let target: String
    let timestamp: Date
    let success: Bool
    let notes: String?

    init(type: ActionType, target: String, success: Bool = true, notes: String? = nil) {
        self.type = type
        self.target = target
        self.timestamp = Date()
        self.success = success
        self.notes = notes
    }
}

enum ActionType: String {
    case tap = "TAP"
    case swipe = "SWIPE"
    case longPress = "LONG_PRESS"
    case navigate = "NAVIGATE"
    case fill = "FILL"
    case selectColor = "SELECT_COLOR"
    case undo = "UNDO"
    case save = "SAVE"
    case share = "SHARE"
    case settings = "SETTINGS"
    case wait = "WAIT"
}

// MARK: - Test Result
struct PersonaTestResult {
    let persona: UserPersona
    let session: TestSession
    let passed: Bool
    let failureReason: String?
    let duration: TimeInterval
    let screensVisited: [String]

    var summary: String {
        """
        ═══════════════════════════════════════
        PERSONA TEST RESULT: \(persona.rawValue)
        Session: \(session.sessionId)
        ═══════════════════════════════════════
        Status: \(passed ? "✅ PASSED" : "❌ FAILED")
        Duration: \(String(format: "%.2f", duration))s
        Actions: \(session.actions.count)
        Screens: \(screensVisited.joined(separator: " → "))
        \(failureReason.map { "Failure: \($0)" } ?? "")
        ═══════════════════════════════════════
        """
    }
}
