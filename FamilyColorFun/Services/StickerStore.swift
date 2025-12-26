import Foundation
import Combine

// MARK: - Sticker Store

final class StickerStore: ObservableObject {
    static let shared = StickerStore()

    // MARK: - Published State

    /// Set of unlocked sticker IDs
    @Published private(set) var unlockedIds: Set<String> = []

    /// Stickers placed on artworks: artworkId → [PlacedSticker]
    @Published private(set) var placements: [String: [PlacedSticker]] = [:]

    // MARK: - Storage Keys

    private let unlockedKey = "sticker_unlocked_ids"
    private let placementsKey = "sticker_placements"

    // MARK: - Init

    private init() {
        load()
        unlockFreeStickers()
        setupProgressionObserver()
    }

    // MARK: - Unlock Logic

    /// Check if a sticker is unlocked
    func isUnlocked(_ stickerId: String) -> Bool {
        unlockedIds.contains(stickerId)
    }

    /// Unlock a sticker by ID
    func unlock(_ stickerId: String) {
        guard !unlockedIds.contains(stickerId) else { return }
        unlockedIds.insert(stickerId)
        save()
    }

    /// Unlock all free stickers
    private func unlockFreeStickers() {
        for sticker in StickerDefinition.allStickers {
            if case .free = sticker.unlockRequirement {
                unlockedIds.insert(sticker.id)
            }
        }
        save()
    }

    /// Check and unlock stickers based on current progression
    func checkUnlocks() {
        let progression = ProgressionEngine.shared
        let totalCompleted = progression.completedPages.count

        for sticker in StickerDefinition.allStickers {
            guard !unlockedIds.contains(sticker.id) else { continue }

            var shouldUnlock = false

            switch sticker.unlockRequirement {
            case .free:
                shouldUnlock = true
            case .starCount(let required):
                shouldUnlock = progression.stars >= required
            case .pagesCompleted(let required):
                shouldUnlock = totalCompleted >= required
            case .categoryComplete(let categoryId):
                // Check if category is complete (all pages done)
                if let category = Category.all.first(where: { $0.categoryId == categoryId }) {
                    shouldUnlock = progression.isCategoryComplete(categoryId, totalPages: category.pages.count)
                } else {
                    #if DEBUG
                    print("⚠️ StickerStore: Category '\(categoryId)' not found for unlock requirement")
                    #endif
                }
            }

            if shouldUnlock {
                unlock(sticker.id)
            }
        }
    }

    // MARK: - Placement

    /// Place a sticker on an artwork
    func place(_ stickerId: String, on artworkId: String, x: Double, y: Double) {
        guard isUnlocked(stickerId) else { return }

        let placed = PlacedSticker(stickerId: stickerId, x: x, y: y)
        var existing = placements[artworkId] ?? []
        existing.append(placed)
        placements[artworkId] = existing
        save()
    }

    /// Update a placed sticker's position/scale/rotation
    func update(_ placedId: UUID, on artworkId: String, x: Double? = nil, y: Double? = nil, scale: Double? = nil, rotation: Double? = nil) {
        guard var stickers = placements[artworkId],
              let index = stickers.firstIndex(where: { $0.id == placedId }) else { return }

        var sticker = stickers[index]
        if let x = x { sticker.x = x }
        if let y = y { sticker.y = y }
        if let scale = scale { sticker.scale = scale }
        if let rotation = rotation { sticker.rotation = rotation }
        stickers[index] = sticker
        placements[artworkId] = stickers
        save()
    }

    /// Remove a placed sticker
    func remove(_ placedId: UUID, from artworkId: String) {
        guard var stickers = placements[artworkId] else { return }
        stickers.removeAll { $0.id == placedId }
        placements[artworkId] = stickers
        save()
    }

    /// Get all stickers placed on an artwork
    func stickers(for artworkId: String) -> [PlacedSticker] {
        placements[artworkId] ?? []
    }

    // MARK: - Observers

    private var cancellables = Set<AnyCancellable>()

    private func setupProgressionObserver() {
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
        // Save unlocked IDs
        let unlockedArray = Array(unlockedIds)
        if let data = try? JSONEncoder().encode(unlockedArray) {
            UserDefaults.standard.set(data, forKey: unlockedKey)
        }

        // Save placements
        if let data = try? JSONEncoder().encode(placements) {
            UserDefaults.standard.set(data, forKey: placementsKey)
        }
    }

    private func load() {
        // Load unlocked IDs
        if let data = UserDefaults.standard.data(forKey: unlockedKey),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            unlockedIds = Set(decoded)
        }

        // Load placements
        if let data = UserDefaults.standard.data(forKey: placementsKey),
           let decoded = try? JSONDecoder().decode([String: [PlacedSticker]].self, from: data) {
            placements = decoded
        }
    }

    // MARK: - Debug

    #if DEBUG
    func resetForTesting() {
        unlockedIds = []
        placements = [:]
        unlockFreeStickers()
        save()
    }

    func unlockAllForTesting() {
        for sticker in StickerDefinition.allStickers {
            unlockedIds.insert(sticker.id)
        }
        save()
    }
    #endif
}
