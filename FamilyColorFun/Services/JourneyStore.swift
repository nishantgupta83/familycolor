import Foundation
import Combine

// MARK: - Journey Record

struct JourneyRecord: Codable, Identifiable {
    var id: String { pageId }
    let pageId: String
    var state: JourneyState
    var progress: Double
    var firstOpened: Date?
    var lastModified: Date?
    var totalTime: TimeInterval
    var sessionStartTime: Date?

    enum JourneyState: String, Codable {
        case notStarted
        case inProgress
        case completed
    }

    init(pageId: String) {
        self.pageId = pageId
        self.state = .notStarted
        self.progress = 0
        self.firstOpened = nil
        self.lastModified = nil
        self.totalTime = 0
        self.sessionStartTime = nil
    }
}

// MARK: - Journey Store

final class JourneyStore: ObservableObject {
    static let shared = JourneyStore()

    @Published private(set) var records: [String: JourneyRecord] = [:]

    private let storageKey = "journey_records"

    private init() {
        load()
    }

    // MARK: - Public API

    /// Start or resume a coloring session
    func startOrResume(pageId: String) {
        var record = records[pageId] ?? JourneyRecord(pageId: pageId)

        if record.firstOpened == nil {
            record.firstOpened = Date()
        }

        record.sessionStartTime = Date()

        if record.state == .notStarted {
            record.state = .inProgress
        }

        records[pageId] = record
        save()
    }

    /// Update progress for a page
    func updateProgress(_ progress: Double, for pageId: String) {
        guard var record = records[pageId] else { return }

        record.progress = progress
        record.lastModified = Date()

        // Update total time if session is active
        if let sessionStart = record.sessionStartTime {
            record.totalTime += Date().timeIntervalSince(sessionStart)
            record.sessionStartTime = Date() // Reset for next interval
        }

        records[pageId] = record
        save()
    }

    /// Mark page as completed
    func markComplete(pageId: String) {
        guard var record = records[pageId] else { return }

        record.state = .completed
        record.progress = 1.0
        record.lastModified = Date()

        // Finalize session time
        if let sessionStart = record.sessionStartTime {
            record.totalTime += Date().timeIntervalSince(sessionStart)
            record.sessionStartTime = nil
        }

        records[pageId] = record
        save()
    }

    /// End session without completing (partial save)
    func endSession(pageId: String) {
        guard var record = records[pageId] else { return }

        // Finalize session time
        if let sessionStart = record.sessionStartTime {
            record.totalTime += Date().timeIntervalSince(sessionStart)
            record.sessionStartTime = nil
        }

        record.lastModified = Date()
        records[pageId] = record
        save()
    }

    /// Check if there's work in progress
    func hasWIP(pageId: String) -> Bool {
        guard let record = records[pageId] else { return false }
        return record.state == .inProgress && record.progress > 0
    }

    /// Get journey state for a page
    func getState(pageId: String) -> JourneyRecord.JourneyState {
        records[pageId]?.state ?? .notStarted
    }

    /// Get progress for a page
    func getProgress(pageId: String) -> Double {
        records[pageId]?.progress ?? 0
    }

    /// Check if page is completed
    func isCompleted(pageId: String) -> Bool {
        records[pageId]?.state == .completed
    }

    // MARK: - Persistence

    private func save() {
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([String: JourneyRecord].self, from: data) {
            records = decoded
        }
    }
}
