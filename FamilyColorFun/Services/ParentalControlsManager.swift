import SwiftUI
import Combine

// MARK: - Parental Controls Manager
class ParentalControlsManager: ObservableObject {
    static let shared = ParentalControlsManager()

    // MARK: - Published Properties

    // Time Limits
    @Published var timeLimitEnabled: Bool {
        didSet { saveSettings() }
    }
    @Published var dailyTimeLimitMinutes: Int {
        didSet { saveSettings() }
    }
    @Published var timeUsedTodayMinutes: Int = 0

    // Child Profiles
    @Published var profiles: [ChildProfile] {
        didSet { saveProfiles() }
    }
    @Published var activeProfileId: UUID? {
        didSet { saveSettings() }
    }

    // Usage Statistics
    @Published var usageHistory: [DailyUsage] {
        didSet { saveUsageHistory() }
    }

    // PIN Protection
    @Published var pinCode: String? {
        didSet { saveSettings() }
    }

    // Time Limit Alert
    @Published var showTimeLimitReached = false

    // MARK: - Private
    private let settingsKey = "parental_settings"
    private let profilesKey = "child_profiles"
    private let usageKey = "usage_history"

    private var sessionTimer: Timer?
    private var sessionStartTime: Date?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Active Profile
    var activeProfile: ChildProfile? {
        profiles.first { $0.id == activeProfileId }
    }

    // MARK: - Today's Usage
    var todayUsage: DailyUsage {
        let today = Calendar.current.startOfDay(for: Date())
        return usageHistory.first { $0.date == today } ?? DailyUsage(date: today)
    }

    // MARK: - Weekly Summary
    var weeklySummary: WeeklySummary {
        WeeklySummary(from: usageHistory)
    }

    // MARK: - Remaining Time
    var remainingMinutes: Int {
        max(0, dailyTimeLimitMinutes - timeUsedTodayMinutes)
    }

    var isTimeLimitReached: Bool {
        timeLimitEnabled && timeUsedTodayMinutes >= dailyTimeLimitMinutes
    }

    // MARK: - Init
    private init() {
        // Set defaults first
        self.timeLimitEnabled = false
        self.dailyTimeLimitMinutes = 30
        self.profiles = []
        self.usageHistory = []

        // Then load saved data
        loadSettings()
        loadProfiles()
        loadUsageHistory()
        updateTodayUsage()
    }

    // MARK: - Session Management
    func startSession() {
        guard !isTimeLimitReached else {
            showTimeLimitReached = true
            return
        }

        sessionStartTime = Date()

        // Start timer to track usage
        sessionTimer?.invalidate()
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.incrementSessionTime()
        }
    }

    func endSession() {
        sessionTimer?.invalidate()
        sessionTimer = nil

        if let start = sessionStartTime {
            let elapsed = Int(Date().timeIntervalSince(start) / 60)
            addUsageTime(minutes: elapsed)
        }

        sessionStartTime = nil
    }

    private func incrementSessionTime() {
        timeUsedTodayMinutes += 1

        // Update today's usage
        var today = todayUsage
        today.minutesColored += 1
        updateUsage(today)

        // Check limit
        if isTimeLimitReached {
            showTimeLimitReached = true
            endSession()
        }
    }

    func addUsageTime(minutes: Int) {
        var today = todayUsage
        today.minutesColored += minutes
        updateUsage(today)
        timeUsedTodayMinutes = today.minutesColored
    }

    func recordPageCompleted(stars: Int) {
        var today = todayUsage
        today.pagesCompleted += 1
        today.starsEarned += stars
        updateUsage(today)
    }

    private func updateUsage(_ usage: DailyUsage) {
        if let index = usageHistory.firstIndex(where: { $0.date == usage.date }) {
            usageHistory[index] = usage
        } else {
            usageHistory.append(usage)
        }
    }

    private func updateTodayUsage() {
        timeUsedTodayMinutes = todayUsage.minutesColored
    }

    // MARK: - Profile Management
    func addProfile(name: String, avatar: String) {
        let profile = ChildProfile(name: name, avatarName: avatar)
        profiles.append(profile)

        // Set as active if first profile
        if profiles.count == 1 {
            activeProfileId = profile.id
        }
    }

    func deleteProfile(_ profile: ChildProfile) {
        profiles.removeAll { $0.id == profile.id }

        // Clear active if deleted
        if activeProfileId == profile.id {
            activeProfileId = profiles.first?.id
        }
    }

    func updateProfile(_ profile: ChildProfile) {
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index] = profile
        }
    }

    func switchProfile(to profileId: UUID) {
        activeProfileId = profileId
    }

    // MARK: - PIN Verification
    func verifyPIN(_ pin: String) -> Bool {
        guard let storedPIN = pinCode else { return true }
        return pin == storedPIN
    }

    func setPIN(_ pin: String) {
        pinCode = pin.isEmpty ? nil : pin
    }

    // MARK: - Time Limit Adjustment
    func adjustTimeLimit(by minutes: Int) {
        let newLimit = max(5, min(180, dailyTimeLimitMinutes + minutes))
        dailyTimeLimitMinutes = newLimit
    }

    // MARK: - Persistence
    private func saveSettings() {
        let settings: [String: Any] = [
            "timeLimitEnabled": timeLimitEnabled,
            "dailyTimeLimitMinutes": dailyTimeLimitMinutes,
            "activeProfileId": activeProfileId?.uuidString ?? "",
            "pinCode": pinCode ?? ""
        ]
        UserDefaults.standard.set(settings, forKey: settingsKey)
    }

    private func loadSettings() {
        guard let settings = UserDefaults.standard.dictionary(forKey: settingsKey) else { return }

        timeLimitEnabled = settings["timeLimitEnabled"] as? Bool ?? false
        dailyTimeLimitMinutes = settings["dailyTimeLimitMinutes"] as? Int ?? 30

        if let idString = settings["activeProfileId"] as? String, !idString.isEmpty {
            activeProfileId = UUID(uuidString: idString)
        }

        let pin = settings["pinCode"] as? String ?? ""
        pinCode = pin.isEmpty ? nil : pin
    }

    private func saveProfiles() {
        if let data = try? JSONEncoder().encode(profiles) {
            UserDefaults.standard.set(data, forKey: profilesKey)
        }
    }

    private func loadProfiles() {
        if let data = UserDefaults.standard.data(forKey: profilesKey),
           let saved = try? JSONDecoder().decode([ChildProfile].self, from: data) {
            profiles = saved
        }
    }

    private func saveUsageHistory() {
        // Keep only last 30 days
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let recentHistory = usageHistory.filter { $0.date >= thirtyDaysAgo }

        if let data = try? JSONEncoder().encode(recentHistory) {
            UserDefaults.standard.set(data, forKey: usageKey)
        }
    }

    private func loadUsageHistory() {
        if let data = UserDefaults.standard.data(forKey: usageKey),
           let saved = try? JSONDecoder().decode([DailyUsage].self, from: data) {
            usageHistory = saved
        }
    }

    // MARK: - Reset (for testing)
    func resetAll() {
        timeLimitEnabled = false
        dailyTimeLimitMinutes = 30
        timeUsedTodayMinutes = 0
        profiles = []
        activeProfileId = nil
        usageHistory = []
        pinCode = nil

        UserDefaults.standard.removeObject(forKey: settingsKey)
        UserDefaults.standard.removeObject(forKey: profilesKey)
        UserDefaults.standard.removeObject(forKey: usageKey)
    }
}
