import SwiftUI
import Combine

// MARK: - Progression Manager
class ProgressionManager: ObservableObject {
    static let shared = ProgressionManager()

    // MARK: - Published Properties
    @Published var userProgress: UserProgress {
        didSet { saveProgress() }
    }

    @Published var rewards: [Reward] {
        didSet { saveRewards() }
    }

    @Published var unlockedSpecialColors: [SpecialColor] = []
    @Published var newlyUnlockedReward: Reward?

    // MARK: - Private
    private let progressKey = "user_progress"
    private let rewardsKey = "user_rewards"

    // MARK: - Init
    private init() {
        self.userProgress = UserProgress()
        self.rewards = Reward.allRewards

        loadProgress()
        loadRewards()
        updateUnlockedColors()
    }

    // MARK: - Star Calculation
    func calculateStars(for progress: Double) -> Int {
        switch progress {
        case 1.0:        return 3  // 100% = 3 stars
        case 0.75..<1.0: return 2  // 75-99% = 2 stars
        case 0.5..<0.75: return 1  // 50-74% = 1 star
        default:         return 0  // <50% = 0 stars
        }
    }

    // MARK: - Record Completion
    func recordPageCompletion(progress: Double) {
        let stars = calculateStars(for: progress)

        // Update progress
        userProgress.addStars(stars)
        if progress >= 0.5 {  // Count as completed if 50%+
            userProgress.completePage()
        }

        // Check for new unlocks
        checkAndUnlockRewards()
    }

    // MARK: - Check Unlocks
    private func checkAndUnlockRewards() {
        for i in 0..<rewards.count {
            if !rewards[i].isUnlocked && meetsRequirement(rewards[i].requirement) {
                rewards[i].isUnlocked = true
                userProgress.unlockedRewardIds.insert(rewards[i].id)
                newlyUnlockedReward = rewards[i]

                // Trigger celebration
                SoundManager.shared.playTap()
            }
        }

        updateUnlockedColors()
    }

    private func meetsRequirement(_ req: RewardRequirement) -> Bool {
        if let pages = req.pagesCompleted, userProgress.totalPagesCompleted < pages {
            return false
        }
        if let stars = req.starsEarned, userProgress.totalStarsEarned < stars {
            return false
        }
        return true
    }

    // MARK: - Special Colors
    private func updateUnlockedColors() {
        var colors: [SpecialColor] = []

        for reward in rewards where reward.isUnlocked && reward.type == .specialColor {
            switch reward.id {
            case "metallic_gold": colors.append(.metallicGold)
            case "unicorn_sparkle": colors.append(.unicornSparkle)
            case "rainbow_shimmer": colors.append(.rainbowShimmer)
            case "silver_glitter": colors.append(.silverGlitter)
            default: break
            }
        }

        unlockedSpecialColors = colors
    }

    // MARK: - Page Unlock Check
    func isPageUnlocked(_ pageId: String) -> Bool {
        // Check if this page requires unlock
        if let pageReward = rewards.first(where: { $0.pageId == pageId }) {
            return pageReward.isUnlocked
        }
        // If no reward tied to this page, it's unlocked by default
        return true
    }

    func getPageUnlockRequirement(_ pageId: String) -> RewardRequirement? {
        rewards.first(where: { $0.pageId == pageId })?.requirement
    }

    // MARK: - Get Progress Towards Reward
    func progressTowards(_ reward: Reward) -> Double {
        var progress: Double = 1.0

        if let pagesReq = reward.requirement.pagesCompleted, pagesReq > 0 {
            progress = min(progress, Double(userProgress.totalPagesCompleted) / Double(pagesReq))
        }

        if let starsReq = reward.requirement.starsEarned, starsReq > 0 {
            progress = min(progress, Double(userProgress.totalStarsEarned) / Double(starsReq))
        }

        return progress
    }

    // MARK: - Persistence
    private func saveProgress() {
        if let data = try? JSONEncoder().encode(userProgress) {
            UserDefaults.standard.set(data, forKey: progressKey)
        }
    }

    private func loadProgress() {
        if let data = UserDefaults.standard.data(forKey: progressKey),
           let progress = try? JSONDecoder().decode(UserProgress.self, from: data) {
            self.userProgress = progress
        }
    }

    private func saveRewards() {
        if let data = try? JSONEncoder().encode(rewards) {
            UserDefaults.standard.set(data, forKey: rewardsKey)
        }
    }

    private func loadRewards() {
        if let data = UserDefaults.standard.data(forKey: rewardsKey),
           let savedRewards = try? JSONDecoder().decode([Reward].self, from: data) {
            // Merge with predefined rewards (in case new rewards were added)
            var mergedRewards = Reward.allRewards
            for i in 0..<mergedRewards.count {
                if let saved = savedRewards.first(where: { $0.id == mergedRewards[i].id }) {
                    mergedRewards[i].isUnlocked = saved.isUnlocked
                }
            }
            self.rewards = mergedRewards
        }
    }

    // MARK: - Reset (for testing)
    func resetProgress() {
        userProgress = UserProgress()
        rewards = Reward.allRewards
        unlockedSpecialColors = []
        UserDefaults.standard.removeObject(forKey: progressKey)
        UserDefaults.standard.removeObject(forKey: rewardsKey)
    }
}
