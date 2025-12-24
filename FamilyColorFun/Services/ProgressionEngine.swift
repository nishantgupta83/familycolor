import Foundation
import Combine

// MARK: - Notifications

extension Notification.Name {
    static let pageCompleted = Notification.Name("pageCompleted")
    static let starsEarned = Notification.Name("starsEarned")
    static let rewardUnlocked = Notification.Name("rewardUnlocked")
}

// MARK: - Progression Engine

final class ProgressionEngine: ObservableObject {
    static let shared = ProgressionEngine()

    // MARK: - Constants

    static let freePages = 3           // First 3 pages per category are free
    static let costPerPage = 5         // 5 stars to unlock a page

    // Star earning values
    static let starsForProgress25 = 1
    static let starsForProgress50 = 1
    static let starsForProgress75 = 1
    static let starsForComplete = 5
    static let starsForCategoryBonus = 10  // Complete 3 in a category
    static let starsForDailyFirst = 5
    static let starsForHelper = 1

    // MARK: - Published State

    @Published private(set) var stars: Int = 0
    @Published private(set) var streak: Int = 0
    @Published private(set) var lastActiveDay: String = ""

    /// categoryId → [unlocked page indices beyond free pages]
    @Published private(set) var unlockedPages: [String: [Int]] = [:]

    /// pageId → set of milestones awarded (25, 50, 75)
    @Published private(set) var progressMilestones: [String: Set<Int>] = [:]

    /// categoryId → [completed pageIds]
    @Published private(set) var completedByCategory: [String: [String]] = [:]

    /// Set of completed page IDs
    @Published private(set) var completedPages: Set<String> = []

    /// Tracks if daily first completion has been awarded today
    private var dailyFirstAwarded: Bool = false

    // MARK: - Storage Keys

    private let storageKey = "progression_engine_state"

    // MARK: - Init

    private init() {
        load()
        checkDayChange()
    }

    // MARK: - Star Earning

    /// Award stars for progress milestones (25%, 50%, 75%)
    func awardProgressMilestone(pageId: String, progress: Double) {
        var milestones = progressMilestones[pageId] ?? []
        var earned = 0

        if progress >= 0.25 && !milestones.contains(25) {
            milestones.insert(25)
            earned += Self.starsForProgress25
        }
        if progress >= 0.50 && !milestones.contains(50) {
            milestones.insert(50)
            earned += Self.starsForProgress50
        }
        if progress >= 0.75 && !milestones.contains(75) {
            milestones.insert(75)
            earned += Self.starsForProgress75
        }

        if earned > 0 {
            progressMilestones[pageId] = milestones
            addStars(earned)
        }
    }

    /// Record page completion and award all applicable stars
    func onPageComplete(pageId: String, categoryId: String) {
        // Don't double-count
        guard !completedPages.contains(pageId) else { return }

        completedPages.insert(pageId)

        // Base completion stars
        addStars(Self.starsForComplete)

        // Track category progress
        var categoryPages = completedByCategory[categoryId] ?? []
        categoryPages.append(pageId)
        completedByCategory[categoryId] = categoryPages

        // Category bonus (every 3 completions)
        if categoryPages.count % 3 == 0 {
            addStars(Self.starsForCategoryBonus)
        }

        // Daily first bonus
        checkDayChange()
        if !dailyFirstAwarded {
            addStars(Self.starsForDailyFirst)
            streak += 1
            dailyFirstAwarded = true
            lastActiveDay = todayString()
        }

        save()

        // Notify listeners
        NotificationCenter.default.post(name: .pageCompleted, object: nil, userInfo: [
            "pageId": pageId,
            "categoryId": categoryId
        ])
    }

    /// Award helper star (anti-frustration)
    func awardHelperStar() {
        addStars(Self.starsForHelper)
    }

    // MARK: - Page Unlocking

    /// Check if a page is unlocked
    func isUnlocked(categoryId: String, index: Int) -> Bool {
        // First N pages are always free
        if index < Self.freePages {
            return true
        }
        // Check if explicitly unlocked
        return unlockedPages[categoryId]?.contains(index) ?? false
    }

    /// Attempt to unlock a page (returns true if successful)
    func unlockPage(categoryId: String, index: Int) -> Bool {
        // Already unlocked?
        guard !isUnlocked(categoryId: categoryId, index: index) else { return true }

        // Can afford?
        guard stars >= Self.costPerPage else { return false }

        // Spend stars and unlock
        stars -= Self.costPerPage
        var pages = unlockedPages[categoryId] ?? []
        pages.append(index)
        unlockedPages[categoryId] = pages

        save()
        return true
    }

    /// Get unlock cost for a page (nil if free or already unlocked)
    func unlockCost(categoryId: String, index: Int) -> Int? {
        if isUnlocked(categoryId: categoryId, index: index) {
            return nil
        }
        return Self.costPerPage
    }

    /// Count of pages completed in a category
    func completedCount(in categoryId: String) -> Int {
        completedByCategory[categoryId]?.count ?? 0
    }

    /// Check if all pages in a category are completed
    func isCategoryComplete(_ categoryId: String, totalPages: Int) -> Bool {
        completedCount(in: categoryId) >= totalPages
    }

    // MARK: - Star Management

    private func addStars(_ amount: Int) {
        stars += amount
        save()
        NotificationCenter.default.post(name: .starsEarned, object: nil, userInfo: [
            "amount": amount,
            "total": stars
        ])
    }

    /// Spend stars (for purchases) - returns true if successful
    func spendStars(_ amount: Int) -> Bool {
        guard stars >= amount else { return false }
        stars -= amount
        save()
        return true
    }

    // MARK: - Streak Management

    private func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        return formatter.string(from: Date())
    }

    private func checkDayChange() {
        let today = todayString()
        if today != lastActiveDay {
            dailyFirstAwarded = false

            // Check if streak should reset (not consecutive day)
            if let lastDate = dateFromString(lastActiveDay),
               let todayDate = dateFromString(today) {
                let calendar = Calendar.current
                if let daysDiff = calendar.dateComponents([.day], from: lastDate, to: todayDate).day,
                   daysDiff > 1 {
                    streak = 0  // Reset streak
                }
            }
        }
    }

    private func dateFromString(_ str: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        return formatter.date(from: str)
    }

    // MARK: - Persistence

    private struct PersistedState: Codable {
        var stars: Int
        var streak: Int
        var lastActiveDay: String
        var unlockedPages: [String: [Int]]
        var progressMilestones: [String: [Int]]  // Convert Set to Array for Codable
        var completedByCategory: [String: [String]]
        var completedPages: [String]
    }

    private func save() {
        let state = PersistedState(
            stars: stars,
            streak: streak,
            lastActiveDay: lastActiveDay,
            unlockedPages: unlockedPages,
            progressMilestones: progressMilestones.mapValues { Array($0) },
            completedByCategory: completedByCategory,
            completedPages: Array(completedPages)
        )

        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let state = try? JSONDecoder().decode(PersistedState.self, from: data) else {
            return
        }

        stars = state.stars
        streak = state.streak
        lastActiveDay = state.lastActiveDay
        unlockedPages = state.unlockedPages
        progressMilestones = state.progressMilestones.mapValues { Set($0) }
        completedByCategory = state.completedByCategory
        completedPages = Set(state.completedPages)
    }

    // MARK: - Debug / Testing

    #if DEBUG
    func resetForTesting() {
        stars = 0
        streak = 0
        lastActiveDay = ""
        unlockedPages = [:]
        progressMilestones = [:]
        completedByCategory = [:]
        completedPages = []
        dailyFirstAwarded = false
        save()
    }

    func addStarsForTesting(_ amount: Int) {
        addStars(amount)
    }
    #endif
}
