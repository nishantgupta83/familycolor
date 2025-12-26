import Foundation
import Combine
import SwiftUI

// MARK: - Companion Controller

final class CompanionController: ObservableObject {
    static let shared = CompanionController()

    // MARK: - Published State

    @Published private(set) var dialogue: String?
    @Published private(set) var animationState: CompanionAnimationState = .idle
    @Published private(set) var isVisible: Bool = true
    @Published private(set) var currentOutfit: CompanionOutfit = .none
    @Published private(set) var unlockedOutfits: Set<String> = []

    /// Position offset for dragging (normalized 0..1)
    @Published var positionX: CGFloat = 0.85
    @Published var positionY: CGFloat = 0.75

    // MARK: - Private State

    private var dialogueDismissTask: Task<Void, Never>?
    private var idleTimer: Timer?
    private var lastInteractionTime = Date()
    private let idleTimeout: TimeInterval = 30 // seconds before sleeping

    // MARK: - Storage Keys

    private let outfitsKey = "companion_unlocked_outfits"
    private let currentOutfitKey = "companion_current_outfit"
    private let positionXKey = "companion_position_x"
    private let positionYKey = "companion_position_y"

    // MARK: - Init

    private init() {
        load()
        unlockFreeOutfits()
        startIdleTimer()
        setupObservers()
    }

    // MARK: - Dialogue Triggers

    /// Trigger a dialogue for a specific phase
    func trigger(_ phase: CompanionPhaseKey, pageName: String? = nil) {
        // Cancel any pending dismissal
        dialogueDismissTask?.cancel()

        // Get dialogue text
        let text = CompanionDialogue.personalized(for: phase, pageName: pageName)
        dialogue = text

        // Set appropriate animation
        animationState = animationFor(phase)

        // Reset interaction time
        lastInteractionTime = Date()

        // Play sound
        SoundManager.shared.playTap()

        // Auto-dismiss after duration based on text length
        let duration = max(2.0, Double(text.count) * 0.08)
        dialogueDismissTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            if !Task.isCancelled {
                withAnimation(.easeOut(duration: 0.3)) {
                    self.dialogue = nil
                    self.animationState = .idle
                }
            }
        }
    }

    /// Trigger random encouragement (for tap interactions)
    func triggerEncouragement() {
        trigger(.encouragement)
    }

    /// Dismiss current dialogue
    func dismissDialogue() {
        dialogueDismissTask?.cancel()
        withAnimation(.easeOut(duration: 0.2)) {
            dialogue = nil
            animationState = .idle
        }
    }

    // MARK: - Animation

    private func animationFor(_ phase: CompanionPhaseKey) -> CompanionAnimationState {
        switch phase {
        case .start, .firstFill, .hint:
            return .talking
        case .progress25, .progress50, .progress75, .encouragement, .colorHint:
            return .waving
        case .completion:
            return .celebrating
        case .partialSave, .returnToWIP:
            return .talking
        case .idle:
            return .sleeping
        }
    }

    // MARK: - Idle Timer

    private func startIdleTimer() {
        idleTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.checkIdleState()
        }
    }

    private func checkIdleState() {
        let elapsed = Date().timeIntervalSince(lastInteractionTime)
        if elapsed > idleTimeout && animationState != .sleeping && dialogue == nil {
            withAnimation(.easeInOut(duration: 0.5)) {
                animationState = .sleeping
            }
            // Occasionally show idle dialogue
            if Int.random(in: 0...3) == 0 {
                dialogue = CompanionDialogue.random(for: .idle)
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    self.dialogue = nil
                }
            }
        }
    }

    func wakeUp() {
        lastInteractionTime = Date()
        if animationState == .sleeping {
            withAnimation(.spring(response: 0.3)) {
                animationState = .idle
            }
        }
    }

    // MARK: - Visibility

    func show() {
        withAnimation(.spring(response: 0.3)) {
            isVisible = true
        }
    }

    func hide() {
        withAnimation(.easeOut(duration: 0.2)) {
            isVisible = false
        }
    }

    // MARK: - Outfits

    func isOutfitUnlocked(_ outfit: CompanionOutfit) -> Bool {
        if case .none = outfit { return true }
        return unlockedOutfits.contains(outfit.rawValue)
    }

    func unlockOutfit(_ outfit: CompanionOutfit) {
        guard !unlockedOutfits.contains(outfit.rawValue) else { return }
        unlockedOutfits.insert(outfit.rawValue)
        save()

        NotificationCenter.default.post(name: .rewardUnlocked, object: nil, userInfo: [
            "type": "companionOutfit",
            "id": outfit.rawValue
        ])
    }

    func setOutfit(_ outfit: CompanionOutfit) {
        guard isOutfitUnlocked(outfit) else { return }
        currentOutfit = outfit
        save()
    }

    private func unlockFreeOutfits() {
        for outfit in CompanionOutfit.allCases {
            if case .free = outfit.unlockRequirement {
                unlockedOutfits.insert(outfit.rawValue)
            }
        }
        save()
    }

    func checkOutfitUnlocks() {
        let progression = ProgressionEngine.shared
        let totalCompleted = progression.completedPages.count

        for outfit in CompanionOutfit.allCases {
            guard !unlockedOutfits.contains(outfit.rawValue) else { continue }

            var shouldUnlock = false

            switch outfit.unlockRequirement {
            case .free:
                shouldUnlock = true
            case .streak(let required):
                shouldUnlock = progression.streak >= required
            case .starCount(let required):
                shouldUnlock = progression.stars >= required
            case .pagesCompleted(let required):
                shouldUnlock = totalCompleted >= required
            case .categoryComplete(let categoryId):
                if let category = Category.all.first(where: { $0.categoryId == categoryId }) {
                    shouldUnlock = progression.isCategoryComplete(categoryId, totalPages: category.pages.count)
                } else {
                    #if DEBUG
                    print("⚠️ CompanionController: Category '\(categoryId)' not found for outfit unlock")
                    #endif
                }
            }

            if shouldUnlock {
                unlockOutfit(outfit)
            }
        }
    }

    // MARK: - Position

    func savePosition() {
        save()
    }

    // MARK: - Observers

    private var cancellables = Set<AnyCancellable>()

    private func setupObservers() {
        NotificationCenter.default.publisher(for: .pageCompleted)
            .sink { [weak self] notification in
                // Trigger completion dialogue
                let pageName = notification.userInfo?["pageId"] as? String
                self?.trigger(.completion, pageName: pageName)
                self?.checkOutfitUnlocks()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .starsEarned)
            .sink { [weak self] notification in
                // Check if significant stars earned (5+) and show encouragement
                if let amount = notification.userInfo?["amount"] as? Int, amount >= 5 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self?.trigger(.encouragement)
                    }
                }
                self?.checkOutfitUnlocks()
            }
            .store(in: &cancellables)
    }

    // MARK: - Persistence

    private func save() {
        let outfitArray = Array(unlockedOutfits)
        if let data = try? JSONEncoder().encode(outfitArray) {
            UserDefaults.standard.set(data, forKey: outfitsKey)
        }
        UserDefaults.standard.set(currentOutfit.rawValue, forKey: currentOutfitKey)
        UserDefaults.standard.set(Double(positionX), forKey: positionXKey)
        UserDefaults.standard.set(Double(positionY), forKey: positionYKey)
    }

    private func load() {
        // Load unlocked outfits
        if let data = UserDefaults.standard.data(forKey: outfitsKey),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            unlockedOutfits = Set(decoded)
        }

        // Load current outfit
        if let outfitRaw = UserDefaults.standard.string(forKey: currentOutfitKey),
           let outfit = CompanionOutfit(rawValue: outfitRaw) {
            currentOutfit = outfit
        }

        // Load position
        if UserDefaults.standard.object(forKey: positionXKey) != nil {
            positionX = CGFloat(UserDefaults.standard.double(forKey: positionXKey))
            positionY = CGFloat(UserDefaults.standard.double(forKey: positionYKey))
        }
    }

    // MARK: - Debug

    #if DEBUG
    func resetForTesting() {
        unlockedOutfits = []
        currentOutfit = .none
        positionX = 0.85
        positionY = 0.75
        dialogue = nil
        animationState = .idle
        unlockFreeOutfits()
        save()
    }
    #endif
}
