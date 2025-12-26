import Foundation

// MARK: - Companion Phase Keys (No Associated Values for Dictionary Keys)

enum CompanionPhaseKey: String, Hashable, CaseIterable {
    case start
    case firstFill
    case progress25
    case progress50
    case progress75
    case completion
    case partialSave
    case returnToWIP
    case idle
    case encouragement
    case hint
    case colorHint  // For intelligent color suggestions
}

// MARK: - Animation State

enum CompanionAnimationState: String, Codable {
    case idle
    case talking
    case celebrating
    case sleeping
    case waving

    var frameCount: Int {
        switch self {
        case .idle: return 4
        case .talking: return 4
        case .celebrating: return 4
        case .sleeping: return 3
        case .waving: return 3
        }
    }

    var frameDuration: Double {
        switch self {
        case .idle: return 0.5
        case .talking: return 0.15
        case .celebrating: return 0.12
        case .sleeping: return 0.8
        case .waving: return 0.2
        }
    }
}

// MARK: - Companion Outfit

enum CompanionOutfit: String, Codable, CaseIterable, Identifiable {
    case none
    case hat
    case scarf
    case cape
    case crown
    case bow

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: return "None"
        case .hat: return "Party Hat"
        case .scarf: return "Cozy Scarf"
        case .cape: return "Super Cape"
        case .crown: return "Royal Crown"
        case .bow: return "Cute Bow"
        }
    }

    var imageName: String {
        "companion_outfit_\(rawValue)"
    }

    var unlockRequirement: OutfitUnlockRequirement {
        switch self {
        case .none: return .free
        case .hat: return .streak(7)
        case .scarf: return .starCount(50)
        case .cape: return .starCount(100)
        case .crown: return .pagesCompleted(25)
        case .bow: return .categoryComplete("animals")
        }
    }

    enum OutfitUnlockRequirement: Codable, Hashable {
        case free
        case streak(Int)
        case starCount(Int)
        case pagesCompleted(Int)
        case categoryComplete(String)
    }
}

// MARK: - Companion Character

struct CompanionCharacter {
    static let name = "Buddy"
    static let defaultOutfit: CompanionOutfit = .none

    /// Base image names for each animation state
    static func frameName(state: CompanionAnimationState, frame: Int) -> String {
        "companion_\(state.rawValue)_\(frame)"
    }
}

// MARK: - Companion Dialogue

struct CompanionDialogue {
    /// Dialogues organized by phase
    static let dialogues: [CompanionPhaseKey: [String]] = [
        .start: [
            "Hey buddy, let's color!",
            "What color do you think looks nice?",
            "Ready to create something amazing?",
            "Let's make this beautiful!"
        ],
        .firstFill: [
            "Great choice!",
            "That color looks perfect!",
            "Nice one!",
            "Ooh, pretty!"
        ],
        .progress25: [
            "You're doing amazing!",
            "Keep going, it looks great!",
            "Wow, so colorful!"
        ],
        .progress50: [
            "Halfway there!",
            "It's looking beautiful!",
            "You're a natural artist!"
        ],
        .progress75: [
            "Almost done!",
            "Just a little more!",
            "You're so close!"
        ],
        .completion: [
            "WOW! Amazing work!",
            "You did it! Beautiful!",
            "What a masterpiece!",
            "I love it! Great job!"
        ],
        .partialSave: [
            "We'll finish this later!",
            "Good work so far!",
            "See you soon!"
        ],
        .returnToWIP: [
            "Welcome back!",
            "Ready to continue?",
            "Let's finish this masterpiece!"
        ],
        .idle: [
            "Zzz...",
            "*yawn*",
            "Hmm hmm hmm...",
            "La la la..."
        ],
        .encouragement: [
            "You can do it!",
            "Keep it up!",
            "You're awesome!",
            "I believe in you!"
        ],
        .hint: [
            "Try a new color!",
            "What about this area?",
            "Use your favorite color!"
        ],
        .colorHint: [
            "Try this color here!",
            "How about this one?",
            "This color would look great!",
            "I have an idea!",
            "Let me help you pick!",
            "Ooh, try this color!",
            "What do you think of this?"
        ]
    ]

    /// Get a random dialogue for a phase
    static func random(for phase: CompanionPhaseKey) -> String {
        dialogues[phase]?.randomElement() ?? "..."
    }

    /// Get a personalized dialogue with page name
    static func personalized(for phase: CompanionPhaseKey, pageName: String?) -> String {
        var text = random(for: phase)
        if let pageName = pageName {
            text = text.replacingOccurrences(of: "{page}", with: pageName)
        }
        return text
    }
}
