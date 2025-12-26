import Foundation

// MARK: - Sticker Definition

struct StickerDefinition: Codable, Identifiable, Hashable {
    let id: String
    let imageName: String
    let category: StickerCategory
    let unlockRequirement: UnlockRequirement

    enum StickerCategory: String, Codable, CaseIterable {
        case stars = "Stars"
        case animals = "Animals"
        case hearts = "Hearts"
        case rainbows = "Rainbows"
        case crowns = "Crowns"
        case trophies = "Trophies"
    }

    enum UnlockRequirement: Codable, Hashable {
        case free
        case starCount(Int)
        case pagesCompleted(Int)
        case categoryComplete(String)
    }
}

// MARK: - Placed Sticker

struct PlacedSticker: Codable, Identifiable, Hashable {
    let id: UUID
    let stickerId: String
    var x: Double  // 0..1 normalized
    var y: Double  // 0..1 normalized
    var scale: Double
    var rotation: Double  // in degrees

    init(stickerId: String, x: Double, y: Double, scale: Double = 1.0, rotation: Double = 0) {
        self.id = UUID()
        self.stickerId = stickerId
        self.x = x
        self.y = y
        self.scale = scale
        self.rotation = rotation
    }
}

// MARK: - Default Stickers

extension StickerDefinition {
    /// MVP set of 12 stickers (2 per category)
    static let allStickers: [StickerDefinition] = [
        // Stars (free)
        StickerDefinition(id: "star_gold", imageName: "sticker_star_gold", category: .stars, unlockRequirement: .free),
        StickerDefinition(id: "star_sparkle", imageName: "sticker_star_sparkle", category: .stars, unlockRequirement: .starCount(10)),

        // Animals
        StickerDefinition(id: "animal_bunny", imageName: "sticker_animal_bunny", category: .animals, unlockRequirement: .free),
        StickerDefinition(id: "animal_bear", imageName: "sticker_animal_bear", category: .animals, unlockRequirement: .pagesCompleted(3)),

        // Hearts
        StickerDefinition(id: "heart_red", imageName: "sticker_heart_red", category: .hearts, unlockRequirement: .free),
        StickerDefinition(id: "heart_rainbow", imageName: "sticker_heart_rainbow", category: .hearts, unlockRequirement: .starCount(25)),

        // Rainbows
        StickerDefinition(id: "rainbow_arc", imageName: "sticker_rainbow_arc", category: .rainbows, unlockRequirement: .pagesCompleted(5)),
        StickerDefinition(id: "rainbow_cloud", imageName: "sticker_rainbow_cloud", category: .rainbows, unlockRequirement: .starCount(50)),

        // Crowns
        StickerDefinition(id: "crown_gold", imageName: "sticker_crown_gold", category: .crowns, unlockRequirement: .pagesCompleted(10)),
        StickerDefinition(id: "crown_princess", imageName: "sticker_crown_princess", category: .crowns, unlockRequirement: .categoryComplete("animals")),

        // Trophies
        StickerDefinition(id: "trophy_gold", imageName: "sticker_trophy_gold", category: .trophies, unlockRequirement: .pagesCompleted(15)),
        StickerDefinition(id: "trophy_star", imageName: "sticker_trophy_star", category: .trophies, unlockRequirement: .starCount(100)),
    ]

    static func sticker(byId id: String) -> StickerDefinition? {
        allStickers.first { $0.id == id }
    }

    static func stickers(in category: StickerCategory) -> [StickerDefinition] {
        allStickers.filter { $0.category == category }
    }
}
