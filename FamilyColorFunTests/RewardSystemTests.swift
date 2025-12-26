import XCTest
@testable import FamilyColorFun

final class RewardSystemTests: XCTestCase {

    // MARK: - ProgressionEngine Tests

    func testProgressionEngineSingleton() {
        let instance1 = ProgressionEngine.shared
        let instance2 = ProgressionEngine.shared
        XCTAssertTrue(instance1 === instance2)
    }

    func testProgressionEngineInitialState() {
        let engine = ProgressionEngine.shared
        XCTAssertGreaterThanOrEqual(engine.stars, 0)
        XCTAssertGreaterThanOrEqual(engine.streak, 0)
    }

    func testProgressionEngineFreePages() {
        XCTAssertEqual(ProgressionEngine.freePages, 3)
    }

    func testProgressionEngineCostPerPage() {
        XCTAssertEqual(ProgressionEngine.costPerPage, 5)
    }

    func testProgressionEngineIsUnlockedForFreePage() {
        let engine = ProgressionEngine.shared
        // First 3 pages should always be unlocked
        XCTAssertTrue(engine.isUnlocked(categoryId: "animals", index: 0))
        XCTAssertTrue(engine.isUnlocked(categoryId: "animals", index: 1))
        XCTAssertTrue(engine.isUnlocked(categoryId: "animals", index: 2))
    }

    // MARK: - JourneyStore Tests

    func testJourneyStoreSingleton() {
        let instance1 = JourneyStore.shared
        let instance2 = JourneyStore.shared
        XCTAssertTrue(instance1 === instance2)
    }

    func testJourneyRecordInitialization() {
        let record = JourneyRecord(pageId: "test_page")
        XCTAssertEqual(record.pageId, "test_page")
        XCTAssertEqual(record.state, .notStarted)
        XCTAssertEqual(record.progress, 0)
        XCTAssertNil(record.firstOpened)
        XCTAssertEqual(record.totalTime, 0)
    }

    func testJourneyRecordStates() {
        XCTAssertEqual(JourneyRecord.JourneyState.notStarted.rawValue, "notStarted")
        XCTAssertEqual(JourneyRecord.JourneyState.inProgress.rawValue, "inProgress")
        XCTAssertEqual(JourneyRecord.JourneyState.completed.rawValue, "completed")
    }

    // MARK: - Sticker Tests

    func testStickerCategoryCount() {
        XCTAssertEqual(StickerDefinition.StickerCategory.allCases.count, 6)
    }

    func testStickerCategoryRawValues() {
        XCTAssertEqual(StickerDefinition.StickerCategory.stars.rawValue, "Stars")
        XCTAssertEqual(StickerDefinition.StickerCategory.animals.rawValue, "Animals")
        XCTAssertEqual(StickerDefinition.StickerCategory.hearts.rawValue, "Hearts")
        XCTAssertEqual(StickerDefinition.StickerCategory.rainbows.rawValue, "Rainbows")
        XCTAssertEqual(StickerDefinition.StickerCategory.crowns.rawValue, "Crowns")
        XCTAssertEqual(StickerDefinition.StickerCategory.trophies.rawValue, "Trophies")
    }

    func testStickerDefinitionAllStickers() {
        XCTAssertEqual(StickerDefinition.allStickers.count, 12)
    }

    func testStickerStoreSingleton() {
        let instance1 = StickerStore.shared
        let instance2 = StickerStore.shared
        XCTAssertTrue(instance1 === instance2)
    }

    func testPlacedStickerInitialization() {
        let sticker = PlacedSticker(stickerId: "star_gold", x: 0.5, y: 0.5)
        XCTAssertEqual(sticker.stickerId, "star_gold")
        XCTAssertEqual(sticker.x, 0.5)
        XCTAssertEqual(sticker.y, 0.5)
        XCTAssertEqual(sticker.scale, 1.0)
        XCTAssertEqual(sticker.rotation, 0)
    }

    // MARK: - Metallic Color Tests

    func testMetallicTypeCount() {
        XCTAssertEqual(MetallicType.allCases.count, 6)
    }

    func testMetallicTypeDisplayNames() {
        XCTAssertEqual(MetallicType.gold.displayName, "Gold")
        XCTAssertEqual(MetallicType.silver.displayName, "Silver")
        XCTAssertEqual(MetallicType.bronze.displayName, "Bronze")
        XCTAssertEqual(MetallicType.roseGold.displayName, "Rose Gold")
        XCTAssertEqual(MetallicType.copper.displayName, "Copper")
        XCTAssertEqual(MetallicType.platinum.displayName, "Platinum")
    }

    func testMetallicColorStoreSingleton() {
        let instance1 = MetallicColorStore.shared
        let instance2 = MetallicColorStore.shared
        XCTAssertTrue(instance1 === instance2)
    }

    func testMetallicColorAllColors() {
        XCTAssertEqual(MetallicColor.allMetallicColors.count, 6)
    }

    // MARK: - Pattern Fill Tests

    func testPatternTypeCount() {
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

    func testPatternFillAllPatterns() {
        XCTAssertEqual(PatternFill.allPatterns.count, 6)
    }

    func testPatternFillStoreSingleton() {
        let instance1 = PatternFillStore.shared
        let instance2 = PatternFillStore.shared
        XCTAssertTrue(instance1 === instance2)
    }

    // MARK: - Companion Tests

    func testCompanionPhaseKeyCount() {
        XCTAssertEqual(CompanionPhaseKey.allCases.count, 11)
    }

    func testCompanionOutfitCount() {
        XCTAssertEqual(CompanionOutfit.allCases.count, 6)
    }

    func testCompanionOutfitDisplayNames() {
        XCTAssertEqual(CompanionOutfit.none.displayName, "None")
        XCTAssertEqual(CompanionOutfit.hat.displayName, "Party Hat")
        XCTAssertEqual(CompanionOutfit.scarf.displayName, "Cozy Scarf")
        XCTAssertEqual(CompanionOutfit.cape.displayName, "Super Cape")
        XCTAssertEqual(CompanionOutfit.crown.displayName, "Royal Crown")
        XCTAssertEqual(CompanionOutfit.bow.displayName, "Cute Bow")
    }

    func testCompanionControllerSingleton() {
        let instance1 = CompanionController.shared
        let instance2 = CompanionController.shared
        XCTAssertTrue(instance1 === instance2)
    }

    func testCompanionControllerInitialState() {
        let controller = CompanionController.shared
        XCTAssertTrue(controller.isVisible)
        XCTAssertNil(controller.dialogue)
    }

    func testCompanionDialogueHasAllPhases() {
        for phase in CompanionPhaseKey.allCases {
            let dialogue = CompanionDialogue.random(for: phase)
            XCTAssertFalse(dialogue.isEmpty, "Dialogue for \(phase) should not be empty")
        }
    }

    // MARK: - Unlock Requirement Tests

    func testUnlockRequirementFree() {
        let req = StickerDefinition.UnlockRequirement.free
        switch req {
        case .free:
            XCTAssertTrue(true)
        default:
            XCTFail("Expected free requirement")
        }
    }

    func testUnlockRequirementStarCount() {
        let req = StickerDefinition.UnlockRequirement.starCount(10)
        switch req {
        case .starCount(let count):
            XCTAssertEqual(count, 10)
        default:
            XCTFail("Expected starCount requirement")
        }
    }

    func testUnlockRequirementPagesCompleted() {
        let req = StickerDefinition.UnlockRequirement.pagesCompleted(5)
        switch req {
        case .pagesCompleted(let count):
            XCTAssertEqual(count, 5)
        default:
            XCTFail("Expected pagesCompleted requirement")
        }
    }

    // MARK: - Math Problem (Parental Gate) Tests

    func testMathProblemGeneration() {
        let problem = MathProblem.generate()
        XCTAssertFalse(problem.question.isEmpty)
        XCTAssertTrue(problem.question.contains("="))
    }

    func testMathProblemAnswerIsReasonable() {
        // Generate multiple problems and verify answers are reasonable
        for _ in 0..<10 {
            let problem = MathProblem.generate()
            XCTAssertGreaterThanOrEqual(problem.answer, -50)
            XCTAssertLessThanOrEqual(problem.answer, 150)
        }
    }
}
