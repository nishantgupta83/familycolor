import SwiftUI

// MARK: - Child Profile
struct ChildProfile: Identifiable, Codable {
    let id: UUID
    var name: String
    var avatarName: String  // SF Symbol name
    var progress: UserProgress
    var createdAt: Date

    init(id: UUID = UUID(), name: String, avatarName: String = "face.smiling") {
        self.id = id
        self.name = name
        self.avatarName = avatarName
        self.progress = UserProgress()
        self.createdAt = Date()
    }

    static let avatarOptions = [
        "face.smiling",
        "face.smiling.inverse",
        "star.fill",
        "heart.fill",
        "sun.max.fill",
        "moon.fill",
        "sparkles",
        "rainbow",
        "pawprint.fill",
        "leaf.fill",
        "cloud.fill",
        "bolt.fill"
    ]
}

// MARK: - Daily Usage
struct DailyUsage: Codable, Identifiable {
    var id: Date { date }
    let date: Date
    var minutesColored: Int
    var pagesCompleted: Int
    var starsEarned: Int

    init(date: Date = Calendar.current.startOfDay(for: Date())) {
        self.date = date
        self.minutesColored = 0
        self.pagesCompleted = 0
        self.starsEarned = 0
    }
}

// MARK: - Weekly Summary
struct WeeklySummary {
    let totalMinutes: Int
    let totalPages: Int
    let totalStars: Int
    let averageMinutesPerDay: Int

    init(from usageHistory: [DailyUsage]) {
        let calendar = Calendar.current
        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()

        let weeklyUsage = usageHistory.filter { $0.date >= oneWeekAgo }

        self.totalMinutes = weeklyUsage.reduce(0) { $0 + $1.minutesColored }
        self.totalPages = weeklyUsage.reduce(0) { $0 + $1.pagesCompleted }
        self.totalStars = weeklyUsage.reduce(0) { $0 + $1.starsEarned }
        self.averageMinutesPerDay = weeklyUsage.isEmpty ? 0 : totalMinutes / max(1, weeklyUsage.count)
    }
}
