import SwiftUI

// MARK: - Metallic Color Type

enum MetallicType: String, Codable, CaseIterable, Identifiable {
    case gold
    case silver
    case bronze
    case roseGold
    case copper
    case platinum

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .gold: return "Gold"
        case .silver: return "Silver"
        case .bronze: return "Bronze"
        case .roseGold: return "Rose Gold"
        case .copper: return "Copper"
        case .platinum: return "Platinum"
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .gold:
            return [
                Color(red: 1.0, green: 0.84, blue: 0.0),
                Color(red: 0.85, green: 0.65, blue: 0.13),
                Color(red: 1.0, green: 0.93, blue: 0.55)
            ]
        case .silver:
            return [
                Color(red: 0.75, green: 0.75, blue: 0.75),
                Color(red: 0.90, green: 0.90, blue: 0.95),
                Color(red: 0.60, green: 0.60, blue: 0.65)
            ]
        case .bronze:
            return [
                Color(red: 0.80, green: 0.50, blue: 0.20),
                Color(red: 0.55, green: 0.35, blue: 0.15),
                Color(red: 0.90, green: 0.65, blue: 0.35)
            ]
        case .roseGold:
            return [
                Color(red: 0.72, green: 0.43, blue: 0.47),
                Color(red: 0.90, green: 0.70, blue: 0.70),
                Color(red: 0.60, green: 0.35, blue: 0.40)
            ]
        case .copper:
            return [
                Color(red: 0.72, green: 0.45, blue: 0.20),
                Color(red: 0.50, green: 0.30, blue: 0.12),
                Color(red: 0.85, green: 0.55, blue: 0.30)
            ]
        case .platinum:
            return [
                Color(red: 0.90, green: 0.89, blue: 0.87),
                Color(red: 0.80, green: 0.80, blue: 0.82),
                Color(red: 0.95, green: 0.95, blue: 0.97)
            ]
        }
    }

    /// Static gradient for canvas fill
    var fillGradient: LinearGradient {
        LinearGradient(
            colors: gradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Get the primary color for basic rendering
    var primaryColor: Color {
        gradientColors[0]
    }

    /// Get UIColor for flood fill
    var uiColor: UIColor {
        UIColor(primaryColor)
    }
}

// MARK: - Metallic Color Definition

struct MetallicColor: Codable, Identifiable, Hashable {
    let id: String
    let type: MetallicType
    let unlockRequirement: MetallicUnlockRequirement

    var displayName: String { type.displayName }
    var gradientColors: [Color] { type.gradientColors }
    var fillGradient: LinearGradient { type.fillGradient }

    enum MetallicUnlockRequirement: Codable, Hashable {
        case starMilestone(Int)
        case categoryComplete(String)
        case streak(Int)
        case pagesCompleted(Int)
    }
}

// MARK: - Default Metallic Colors

extension MetallicColor {
    /// MVP set of metallic colors
    static let allMetallicColors: [MetallicColor] = [
        MetallicColor(id: "gold", type: .gold, unlockRequirement: .starMilestone(10)),
        MetallicColor(id: "silver", type: .silver, unlockRequirement: .starMilestone(25)),
        MetallicColor(id: "bronze", type: .bronze, unlockRequirement: .pagesCompleted(5)),
        MetallicColor(id: "roseGold", type: .roseGold, unlockRequirement: .starMilestone(100)),
        MetallicColor(id: "copper", type: .copper, unlockRequirement: .streak(3)),
        MetallicColor(id: "platinum", type: .platinum, unlockRequirement: .starMilestone(200)),
    ]

    static func metallicColor(byId id: String) -> MetallicColor? {
        allMetallicColors.first { $0.id == id }
    }
}

// MARK: - Metallic Color Store

final class MetallicColorStore: ObservableObject {
    static let shared = MetallicColorStore()

    @Published private(set) var unlockedIds: Set<String> = []

    private let storageKey = "metallic_colors_unlocked"

    private init() {
        load()
        checkUnlocks()
        setupObservers()
    }

    // MARK: - Unlock Logic

    func isUnlocked(_ colorId: String) -> Bool {
        unlockedIds.contains(colorId)
    }

    func unlock(_ colorId: String) {
        guard !unlockedIds.contains(colorId) else { return }
        unlockedIds.insert(colorId)
        save()

        // Notify about unlock
        NotificationCenter.default.post(name: .rewardUnlocked, object: nil, userInfo: [
            "type": "metallicColor",
            "id": colorId
        ])
    }

    func checkUnlocks() {
        let progression = ProgressionEngine.shared
        let totalCompleted = progression.completedPages.count

        for metallic in MetallicColor.allMetallicColors {
            guard !unlockedIds.contains(metallic.id) else { continue }

            var shouldUnlock = false

            switch metallic.unlockRequirement {
            case .starMilestone(let required):
                shouldUnlock = progression.stars >= required
            case .categoryComplete(let categoryId):
                if let category = Category.all.first(where: { $0.categoryId == categoryId }) {
                    shouldUnlock = progression.isCategoryComplete(categoryId, totalPages: category.pages.count)
                } else {
                    #if DEBUG
                    print("⚠️ MetallicColorStore: Category '\(categoryId)' not found for unlock requirement")
                    #endif
                }
            case .streak(let required):
                shouldUnlock = progression.streak >= required
            case .pagesCompleted(let required):
                shouldUnlock = totalCompleted >= required
            }

            if shouldUnlock {
                unlock(metallic.id)
            }
        }
    }

    /// Get all unlocked metallic colors
    var unlockedColors: [MetallicColor] {
        MetallicColor.allMetallicColors.filter { unlockedIds.contains($0.id) }
    }

    // MARK: - Observers

    private var cancellables = Set<AnyCancellable>()

    private func setupObservers() {
        NotificationCenter.default.publisher(for: .pageCompleted)
            .sink { [weak self] _ in
                self?.checkUnlocks()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .starsEarned)
            .sink { [weak self] _ in
                self?.checkUnlocks()
            }
            .store(in: &cancellables)
    }

    // MARK: - Persistence

    private func save() {
        let array = Array(unlockedIds)
        if let data = try? JSONEncoder().encode(array) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            unlockedIds = Set(decoded)
        }
    }

    #if DEBUG
    func resetForTesting() {
        unlockedIds = []
        save()
    }

    func unlockAllForTesting() {
        for metallic in MetallicColor.allMetallicColors {
            unlockedIds.insert(metallic.id)
        }
        save()
    }
    #endif
}

// Need to import Combine for AnyCancellable
import Combine
