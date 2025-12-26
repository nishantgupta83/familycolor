import XCTest
@testable import FamilyColorFun

final class ModelTests: XCTestCase {

    // MARK: - ChildProfile Tests

    func testChildProfileInitialization() {
        let profile = ChildProfile(name: "Test Child")
        XCTAssertEqual(profile.name, "Test Child")
        XCTAssertEqual(profile.avatarName, "face.smiling")
        XCTAssertEqual(profile.progress.totalPagesCompleted, 0)
        XCTAssertEqual(profile.progress.totalStarsEarned, 0)
    }

    func testChildProfileWithCustomAvatar() {
        let profile = ChildProfile(name: "Star Child", avatarName: "star.fill")
        XCTAssertEqual(profile.avatarName, "star.fill")
    }

    func testChildProfileAvatarOptions() {
        XCTAssertTrue(ChildProfile.avatarOptions.contains("face.smiling"))
        XCTAssertTrue(ChildProfile.avatarOptions.contains("star.fill"))
        XCTAssertTrue(ChildProfile.avatarOptions.contains("rainbow"))
        XCTAssertEqual(ChildProfile.avatarOptions.count, 12)
    }

    // MARK: - DailyUsage Tests

    func testDailyUsageInitialization() {
        let usage = DailyUsage()
        XCTAssertEqual(usage.minutesColored, 0)
        XCTAssertEqual(usage.pagesCompleted, 0)
        XCTAssertEqual(usage.starsEarned, 0)
    }

    func testDailyUsageId() {
        let usage = DailyUsage()
        XCTAssertEqual(usage.id, usage.date)
    }

    // MARK: - WeeklySummary Tests

    func testWeeklySummaryEmpty() {
        let summary = WeeklySummary(from: [])
        XCTAssertEqual(summary.totalMinutes, 0)
        XCTAssertEqual(summary.totalPages, 0)
        XCTAssertEqual(summary.totalStars, 0)
        XCTAssertEqual(summary.averageMinutesPerDay, 0)
    }

    // MARK: - RewardType Tests

    func testRewardTypeAllCases() {
        XCTAssertEqual(RewardType.allCases.count, 3)
    }

    func testRewardTypeRawValues() {
        XCTAssertEqual(RewardType.specialColor.rawValue, "Special Color")
        XCTAssertEqual(RewardType.coloringPage.rawValue, "Coloring Page")
        XCTAssertEqual(RewardType.badge.rawValue, "Badge")
    }

    func testRewardTypeIcons() {
        XCTAssertEqual(RewardType.specialColor.icon, "paintpalette.fill")
        XCTAssertEqual(RewardType.coloringPage.icon, "doc.richtext")
        XCTAssertEqual(RewardType.badge.icon, "medal.fill")
    }

    // MARK: - RewardRequirement Tests

    func testRewardRequirementDescriptionBoth() {
        let requirement = RewardRequirement(pagesCompleted: 5, starsEarned: 25)
        XCTAssertEqual(requirement.description, "5 pages & 25 stars")
    }

    func testRewardRequirementDescriptionPagesOnly() {
        let requirement = RewardRequirement(pagesCompleted: 10, starsEarned: nil)
        XCTAssertEqual(requirement.description, "10 pages completed")
    }

    func testRewardRequirementDescriptionStarsOnly() {
        let requirement = RewardRequirement(pagesCompleted: nil, starsEarned: 50)
        XCTAssertEqual(requirement.description, "50 stars earned")
    }

    func testRewardRequirementDescriptionNone() {
        let requirement = RewardRequirement(pagesCompleted: nil, starsEarned: nil)
        XCTAssertEqual(requirement.description, "Unknown")
    }

    // MARK: - UserProgress Tests

    func testUserProgressInitialization() {
        let progress = UserProgress()
        XCTAssertEqual(progress.totalPagesCompleted, 0)
        XCTAssertEqual(progress.totalStarsEarned, 0)
        XCTAssertEqual(progress.currentStreak, 0)
        XCTAssertNil(progress.lastColoredDate)
    }

    func testUserProgressAddStars() {
        var progress = UserProgress()
        progress.addStars(10)
        XCTAssertEqual(progress.totalStarsEarned, 10)
        progress.addStars(5)
        XCTAssertEqual(progress.totalStarsEarned, 15)
    }

    func testUserProgressCompletePage() {
        var progress = UserProgress()
        progress.completePage()
        XCTAssertEqual(progress.totalPagesCompleted, 1)
        XCTAssertEqual(progress.currentStreak, 1)
        XCTAssertNotNil(progress.lastColoredDate)
    }

    // MARK: - SpecialColor Tests

    func testSpecialColorMetallicGold() {
        let gold = SpecialColor.metallicGold
        XCTAssertEqual(gold.id, "metallic_gold")
        XCTAssertEqual(gold.name, "Metallic Gold")
        XCTAssertTrue(gold.isMetallic)
        XCTAssertFalse(gold.isSparkle)
    }

    func testSpecialColorUnicornSparkle() {
        let unicorn = SpecialColor.unicornSparkle
        XCTAssertEqual(unicorn.id, "unicorn_sparkle")
        XCTAssertFalse(unicorn.isMetallic)
        XCTAssertTrue(unicorn.isSparkle)
    }

    func testSpecialColorRainbowShimmer() {
        let rainbow = SpecialColor.rainbowShimmer
        XCTAssertTrue(rainbow.isMetallic)
        XCTAssertTrue(rainbow.isSparkle)
    }

    // MARK: - Reward Tests

    func testRewardAllRewardsCount() {
        XCTAssertEqual(Reward.allRewards.count, 10)
    }

    func testRewardTypeCounts() {
        let specialColors = Reward.allRewards.filter { $0.type == .specialColor }
        let badges = Reward.allRewards.filter { $0.type == .badge }
        let pages = Reward.allRewards.filter { $0.type == .coloringPage }

        XCTAssertEqual(specialColors.count, 4)
        XCTAssertEqual(badges.count, 3)
        XCTAssertEqual(pages.count, 3)
    }

    func testRewardInitiallyLocked() {
        for reward in Reward.allRewards {
            XCTAssertFalse(reward.isUnlocked, "Reward \(reward.id) should be initially locked")
        }
    }

    // MARK: - MetallicType Tests

    func testMetallicTypeAllCases() {
        XCTAssertEqual(MetallicType.allCases.count, 6)
    }

    func testMetallicTypeRawValues() {
        XCTAssertEqual(MetallicType.gold.rawValue, "gold")
        XCTAssertEqual(MetallicType.silver.rawValue, "silver")
        XCTAssertEqual(MetallicType.bronze.rawValue, "bronze")
        XCTAssertEqual(MetallicType.roseGold.rawValue, "roseGold")
        XCTAssertEqual(MetallicType.copper.rawValue, "copper")
        XCTAssertEqual(MetallicType.platinum.rawValue, "platinum")
    }

    func testMetallicTypeGradientColors() {
        for type in MetallicType.allCases {
            XCTAssertEqual(type.gradientColors.count, 3)
        }
    }

    func testMetallicTypeDisplayNames() {
        XCTAssertEqual(MetallicType.gold.displayName, "Gold")
        XCTAssertEqual(MetallicType.silver.displayName, "Silver")
        XCTAssertEqual(MetallicType.roseGold.displayName, "Rose Gold")
    }

    // MARK: - MetallicColor Tests

    func testMetallicColorAllColorsCount() {
        XCTAssertEqual(MetallicColor.allMetallicColors.count, 6)
    }

    func testMetallicColorProperties() {
        for color in MetallicColor.allMetallicColors {
            XCTAssertFalse(color.id.isEmpty)
            XCTAssertFalse(color.displayName.isEmpty)
        }
    }

    func testMetallicColorById() {
        let gold = MetallicColor.metallicColor(byId: "gold")
        XCTAssertNotNil(gold)
        XCTAssertEqual(gold?.type, .gold)
    }

    func testMetallicColorByIdNotFound() {
        let notFound = MetallicColor.metallicColor(byId: "nonexistent")
        XCTAssertNil(notFound)
    }

    // MARK: - PatternType Tests

    func testPatternTypeAllCases() {
        XCTAssertEqual(PatternType.allCases.count, 6)
    }

    func testPatternTypeDisplayNames() {
        XCTAssertEqual(PatternType.polkaDots.displayName, "Polka Dots")
        XCTAssertEqual(PatternType.stripes.displayName, "Stripes")
        XCTAssertEqual(PatternType.zigzag.displayName, "Zigzag")
        XCTAssertEqual(PatternType.hearts.displayName, "Hearts")
        XCTAssertEqual(PatternType.stars.displayName, "Stars")
        XCTAssertEqual(PatternType.checkers.displayName, "Checkers")
    }

    func testPatternTypeIconNames() {
        XCTAssertEqual(PatternType.polkaDots.iconName, "circle.grid.3x3.fill")
        XCTAssertEqual(PatternType.stripes.iconName, "line.3.horizontal")
        XCTAssertEqual(PatternType.zigzag.iconName, "waveform.path")
    }

    // MARK: - PatternFill Tests

    func testPatternFillAllPatternsCount() {
        XCTAssertEqual(PatternFill.allPatterns.count, 6)
    }

    func testPatternFillById() {
        let polkaDots = PatternFill.pattern(byId: "polkaDots")
        XCTAssertNotNil(polkaDots)
        XCTAssertEqual(polkaDots?.type, .polkaDots)
    }

    func testPatternFillByIdNotFound() {
        let notFound = PatternFill.pattern(byId: "nonexistent")
        XCTAssertNil(notFound)
    }

    // MARK: - StickerDefinition Tests

    func testStickerDefinitionAllStickersCount() {
        XCTAssertEqual(StickerDefinition.allStickers.count, 12)
    }

    func testStickerDefinitionStickersInCategory() {
        let stars = StickerDefinition.stickers(in: .stars)
        XCTAssertEqual(stars.count, 2)

        let animals = StickerDefinition.stickers(in: .animals)
        XCTAssertEqual(animals.count, 2)
    }

    func testStickerDefinitionById() {
        let sticker = StickerDefinition.sticker(byId: "star_gold")
        XCTAssertNotNil(sticker)
        XCTAssertEqual(sticker?.category, .stars)
    }

    func testStickerDefinitionByIdNotFound() {
        let sticker = StickerDefinition.sticker(byId: "nonexistent")
        XCTAssertNil(sticker)
    }

    // MARK: - PlacedSticker Tests

    func testPlacedStickerInitialization() {
        let sticker = PlacedSticker(stickerId: "star_gold", x: 0.5, y: 0.5)
        XCTAssertEqual(sticker.stickerId, "star_gold")
        XCTAssertEqual(sticker.x, 0.5)
        XCTAssertEqual(sticker.y, 0.5)
        XCTAssertEqual(sticker.scale, 1.0)
        XCTAssertEqual(sticker.rotation, 0)
    }

    func testPlacedStickerWithCustomScaleAndRotation() {
        let sticker = PlacedSticker(stickerId: "heart_red", x: 0.3, y: 0.7, scale: 1.5, rotation: 45)
        XCTAssertEqual(sticker.scale, 1.5)
        XCTAssertEqual(sticker.rotation, 45)
    }

    // MARK: - CompanionPhaseKey Tests

    func testCompanionPhaseKeyAllCases() {
        XCTAssertEqual(CompanionPhaseKey.allCases.count, 11)
    }

    func testCompanionPhaseKeyRawValues() {
        XCTAssertEqual(CompanionPhaseKey.start.rawValue, "start")
        XCTAssertEqual(CompanionPhaseKey.firstFill.rawValue, "firstFill")
        XCTAssertEqual(CompanionPhaseKey.completion.rawValue, "completion")
        XCTAssertEqual(CompanionPhaseKey.idle.rawValue, "idle")
    }

    // MARK: - CompanionOutfit Tests

    func testCompanionOutfitAllCases() {
        XCTAssertEqual(CompanionOutfit.allCases.count, 6)
    }

    func testCompanionOutfitUnlockRequirements() {
        for outfit in CompanionOutfit.allCases {
            XCTAssertNotNil(outfit.unlockRequirement)
        }
    }

    // MARK: - Category Tests

    func testCategoryAllCount() {
        XCTAssertEqual(Category.all.count, 9)
    }

    func testCategoryAllHavePages() {
        for category in Category.all {
            XCTAssertFalse(category.pages.isEmpty, "Category \(category.name) should have pages")
        }
    }

    func testCategoryIds() {
        let ids = Category.all.map { $0.categoryId }
        XCTAssertTrue(ids.contains("animals"))
        XCTAssertTrue(ids.contains("vehicles"))
        XCTAssertTrue(ids.contains("houses"))
        XCTAssertTrue(ids.contains("nature"))
        XCTAssertTrue(ids.contains("ocean"))
    }

    // MARK: - ColoringPage Tests

    func testColoringPageAnimalsCount() {
        XCTAssertEqual(ColoringPage.animals.count, 15)
    }

    func testColoringPageVehiclesCount() {
        XCTAssertEqual(ColoringPage.vehicles.count, 15)
    }

    func testColoringPageHousesCount() {
        XCTAssertEqual(ColoringPage.houses.count, 12)
    }

    func testColoringPageNatureCount() {
        XCTAssertEqual(ColoringPage.nature.count, 14)
    }

    func testColoringPageOceanCount() {
        XCTAssertEqual(ColoringPage.ocean.count, 14)
    }

    func testColoringPageUniqueImageNames() {
        var allImageNames = Set<String>()
        for category in Category.all {
            for page in category.pages {
                XCTAssertFalse(allImageNames.contains(page.imageName),
                    "Duplicate image name found: \(page.imageName)")
                allImageNames.insert(page.imageName)
            }
        }
    }

    // MARK: - DrawingPath Tests

    func testDrawingPathInitialization() {
        let path = DrawingPath(color: .red, lineWidth: 5.0)
        XCTAssertEqual(path.lineWidth, 5.0)
        XCTAssertTrue(path.points.isEmpty)
        XCTAssertFalse(path.isEraser)
    }

    func testDrawingPathDefaults() {
        let path = DrawingPath()
        XCTAssertEqual(path.lineWidth, 8)
        XCTAssertFalse(path.isEraser)
    }

    func testDrawingPathEraser() {
        let path = DrawingPath(color: .white, lineWidth: 10.0, isEraser: true)
        XCTAssertTrue(path.isEraser)
    }

    func testDrawingPathAddPoint() {
        var path = DrawingPath(color: .blue, lineWidth: 3.0)
        path.points.append(CGPoint(x: 10, y: 20))
        path.points.append(CGPoint(x: 30, y: 40))
        XCTAssertEqual(path.points.count, 2)
    }

    func testDrawingPathWithPoints() {
        let points = [CGPoint(x: 0, y: 0), CGPoint(x: 50, y: 50)]
        let path = DrawingPath(points: points, color: .green, lineWidth: 4.0)
        XCTAssertEqual(path.points.count, 2)
    }

    // MARK: - FilledArea Tests

    func testFilledAreaInitialization() {
        let area = FilledArea(point: CGPoint(x: 100, y: 100), color: .green)
        XCTAssertEqual(area.point, CGPoint(x: 100, y: 100))
        XCTAssertNotNil(area.id)
    }

    // MARK: - Artwork Tests

    func testArtworkInitialization() {
        let pageId = UUID()
        let artwork = Artwork(pageId: pageId, pageName: "Test Page", categoryName: "Test Category", imagePath: "/test/path")
        XCTAssertEqual(artwork.pageId, pageId)
        XCTAssertEqual(artwork.pageName, "Test Page")
        XCTAssertEqual(artwork.categoryName, "Test Category")
        XCTAssertEqual(artwork.imagePath, "/test/path")
        XCTAssertEqual(artwork.progress, 0)
    }

    func testArtworkWithProgress() {
        let artwork = Artwork(pageId: UUID(), pageName: "Test", categoryName: "Cat", imagePath: "/path", progress: 0.5)
        XCTAssertEqual(artwork.progress, 0.5)
    }

    func testArtworkCodable() {
        let original = Artwork(pageId: UUID(), pageName: "Test", categoryName: "Cat", imagePath: "/path")

        do {
            let data = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(Artwork.self, from: data)
            XCTAssertEqual(decoded.pageName, original.pageName)
            XCTAssertEqual(decoded.categoryName, original.categoryName)
        } catch {
            XCTFail("Codable failed: \(error)")
        }
    }
}
