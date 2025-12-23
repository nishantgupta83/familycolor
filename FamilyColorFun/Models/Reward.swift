import SwiftUI

// MARK: - Reward Types
enum RewardType: String, Codable, CaseIterable {
    case specialColor = "Special Color"
    case coloringPage = "Coloring Page"
    case badge = "Badge"

    var icon: String {
        switch self {
        case .specialColor: return "paintpalette.fill"
        case .coloringPage: return "doc.richtext"
        case .badge: return "medal.fill"
        }
    }
}

// MARK: - Reward Requirement
struct RewardRequirement: Codable {
    let pagesCompleted: Int?
    let starsEarned: Int?

    var description: String {
        if let pages = pagesCompleted, let stars = starsEarned {
            return "\(pages) pages & \(stars) stars"
        } else if let pages = pagesCompleted {
            return "\(pages) pages completed"
        } else if let stars = starsEarned {
            return "\(stars) stars earned"
        }
        return "Unknown"
    }
}

// MARK: - Reward
struct Reward: Identifiable, Codable {
    let id: String
    let type: RewardType
    let name: String
    let description: String
    let requirement: RewardRequirement
    var isUnlocked: Bool

    // For special colors
    var colorValue: String?  // Hex color

    // For coloring pages
    var pageId: String?
}

// MARK: - User Progress
struct UserProgress: Codable {
    var totalPagesCompleted: Int = 0
    var totalStarsEarned: Int = 0
    var currentStreak: Int = 0
    var lastColoredDate: Date?
    var unlockedRewardIds: Set<String> = []

    mutating func addStars(_ stars: Int) {
        totalStarsEarned += stars
    }

    mutating func completePage() {
        totalPagesCompleted += 1
        updateStreak()
    }

    private mutating func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastDate = lastColoredDate {
            let lastDay = calendar.startOfDay(for: lastDate)
            let daysDiff = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

            if daysDiff == 1 {
                currentStreak += 1
            } else if daysDiff > 1 {
                currentStreak = 1
            }
        } else {
            currentStreak = 1
        }

        lastColoredDate = Date()
    }
}

// MARK: - Special Colors
struct SpecialColor: Identifiable {
    let id: String
    let name: String
    let color: Color
    let isMetallic: Bool
    let isSparkle: Bool

    static let metallicGold = SpecialColor(
        id: "metallic_gold",
        name: "Metallic Gold",
        color: Color(red: 1.0, green: 0.84, blue: 0.0),
        isMetallic: true,
        isSparkle: false
    )

    static let unicornSparkle = SpecialColor(
        id: "unicorn_sparkle",
        name: "Unicorn Sparkle",
        color: Color(red: 1.0, green: 0.75, blue: 0.8),
        isMetallic: false,
        isSparkle: true
    )

    static let rainbowShimmer = SpecialColor(
        id: "rainbow_shimmer",
        name: "Rainbow Shimmer",
        color: Color(red: 0.5, green: 0.0, blue: 1.0),
        isMetallic: true,
        isSparkle: true
    )

    static let silverGlitter = SpecialColor(
        id: "silver_glitter",
        name: "Silver Glitter",
        color: Color(red: 0.75, green: 0.75, blue: 0.75),
        isMetallic: true,
        isSparkle: true
    )

    static let rosePink = SpecialColor(
        id: "rose_pink",
        name: "Rose Pink",
        color: Color(red: 1.0, green: 0.4, blue: 0.6),
        isMetallic: false,
        isSparkle: true
    )
}

// MARK: - Predefined Rewards
extension Reward {
    static let allRewards: [Reward] = [
        // Special Colors
        Reward(
            id: "metallic_gold",
            type: .specialColor,
            name: "Metallic Gold",
            description: "A shiny gold color for royal artwork!",
            requirement: RewardRequirement(pagesCompleted: 5, starsEarned: nil),
            isUnlocked: false,
            colorValue: "#FFD700"
        ),
        Reward(
            id: "unicorn_sparkle",
            type: .specialColor,
            name: "Unicorn Sparkle",
            description: "Magical pink with sparkles!",
            requirement: RewardRequirement(pagesCompleted: nil, starsEarned: 25),
            isUnlocked: false,
            colorValue: "#FFB6C1"
        ),
        Reward(
            id: "rainbow_shimmer",
            type: .specialColor,
            name: "Rainbow Shimmer",
            description: "All colors in one magical color!",
            requirement: RewardRequirement(pagesCompleted: 10, starsEarned: nil),
            isUnlocked: false,
            colorValue: "#8000FF"
        ),
        Reward(
            id: "silver_glitter",
            type: .specialColor,
            name: "Silver Glitter",
            description: "Sparkling silver for special details!",
            requirement: RewardRequirement(pagesCompleted: nil, starsEarned: 50),
            isUnlocked: false,
            colorValue: "#C0C0C0"
        ),

        // Badges
        Reward(
            id: "rising_star",
            type: .badge,
            name: "Rising Star",
            description: "Complete 3 coloring pages",
            requirement: RewardRequirement(pagesCompleted: 3, starsEarned: nil),
            isUnlocked: false
        ),
        Reward(
            id: "color_champion",
            type: .badge,
            name: "Color Champion",
            description: "Earn 100 stars total",
            requirement: RewardRequirement(pagesCompleted: nil, starsEarned: 100),
            isUnlocked: false
        ),
        Reward(
            id: "master_artist",
            type: .badge,
            name: "Master Artist",
            description: "Complete 25 coloring pages",
            requirement: RewardRequirement(pagesCompleted: 25, starsEarned: nil),
            isUnlocked: false
        ),

        // Locked Coloring Pages
        Reward(
            id: "page_dinosaur_pack",
            type: .coloringPage,
            name: "Dinosaur Pack",
            description: "Unlock amazing dinosaur pages!",
            requirement: RewardRequirement(pagesCompleted: nil, starsEarned: 50),
            isUnlocked: false,
            pageId: "dinosaur_pack"
        ),
        Reward(
            id: "page_space_adventure",
            type: .coloringPage,
            name: "Space Adventures",
            description: "Rockets, planets, and aliens!",
            requirement: RewardRequirement(pagesCompleted: 15, starsEarned: nil),
            isUnlocked: false,
            pageId: "space_adventure"
        ),
        Reward(
            id: "page_underwater",
            type: .coloringPage,
            name: "Underwater World",
            description: "Deep sea creatures await!",
            requirement: RewardRequirement(pagesCompleted: 8, starsEarned: nil),
            isUnlocked: false,
            pageId: "underwater"
        )
    ]
}
