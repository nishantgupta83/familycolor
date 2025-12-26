import SwiftUI
import Combine

// MARK: - Color Suggestion Service

final class ColorSuggestionService: ObservableObject {
    static let shared = ColorSuggestionService()

    // MARK: - Published State

    @Published private(set) var currentSuggestions: [ColorSuggestion] = []
    @Published private(set) var isShowingSuggestions: Bool = false

    // MARK: - Configuration

    private let minIdleTime: TimeInterval = 15.0  // seconds
    private let maxIdleTime: TimeInterval = 30.0  // seconds
    private let maxSuggestionsToShow: Int = 3

    // MARK: - Private State

    private var idleTimer: Timer?
    private var currentIdleThreshold: TimeInterval = 20.0

    // MARK: - Init

    private init() {
        randomizeIdleThreshold()
    }

    // MARK: - Public API

    /// Generate color suggestions for unfilled regions
    /// - Parameters:
    ///   - fillEngine: The current FillEngine with region data
    ///   - pageName: The page name for keyword matching
    ///   - categoryId: The category ID for fallback colors
    ///   - mode: Realistic or creative mode
    ///   - palette: Current color palette
    /// - Returns: Array of ColorSuggestion objects
    func generateSuggestions(
        fillEngine: FillEngine,
        pageName: String,
        categoryId: String,
        mode: ColorSuggestionMode,
        palette: [Color]
    ) -> [ColorSuggestion] {

        guard let metadata = fillEngine.metadata else { return [] }

        // Get unfilled regions, prioritize largest (easiest for kids)
        let unfilledRegions = metadata.regions
            .filter { !fillEngine.filledRegions.contains($0.id) }
            .sorted { $0.pixelCount > $1.pixelCount }
            .prefix(maxSuggestionsToShow)

        guard !unfilledRegions.isEmpty else { return [] }

        // Get appropriate color indices based on mode
        let colorIndices: [Int]
        switch mode {
        case .realistic:
            colorIndices = SubjectColorMap.colorsFor(pageName: pageName, categoryId: categoryId)
        case .creative:
            colorIndices = Array(0..<palette.count).shuffled()
        }

        // Create suggestions
        var suggestions: [ColorSuggestion] = []
        for (index, region) in unfilledRegions.enumerated() {
            let paletteIndex = colorIndices[safe: index % colorIndices.count] ?? 0
            let color = palette[safe: paletteIndex] ?? palette.first ?? .blue

            suggestions.append(ColorSuggestion(
                regionId: region.id,
                suggestedColor: color,
                paletteIndex: paletteIndex,
                centroid: region.centroid,
                boundingBox: region.boundingBox
            ))
        }

        return suggestions
    }

    /// Show suggestions with animation
    func showSuggestions(_ suggestions: [ColorSuggestion]) {
        currentSuggestions = suggestions
        withAnimation(.spring(response: 0.4)) {
            isShowingSuggestions = true
        }
    }

    /// Hide suggestions
    func hideSuggestions() {
        withAnimation(.easeOut(duration: 0.2)) {
            isShowingSuggestions = false
        }
        // Clear after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.currentSuggestions = []
        }
    }

    /// Apply a suggestion (fill the region with suggested color)
    func applySuggestion(_ suggestion: ColorSuggestion, to fillEngine: FillEngine, imageSize: CGSize) {
        let normalizedPoint = CGPoint(
            x: suggestion.centroid.x / imageSize.width,
            y: suggestion.centroid.y / imageSize.height
        )

        let color = UIColor(suggestion.suggestedColor)
        fillEngine.fill(at: normalizedPoint, with: color, paletteIndex: suggestion.paletteIndex)

        // Remove this suggestion from list
        currentSuggestions.removeAll { $0.id == suggestion.id }

        // Hide if no more suggestions
        if currentSuggestions.isEmpty {
            hideSuggestions()
        }
    }

    /// Remove a specific suggestion without applying it
    func removeSuggestion(_ suggestion: ColorSuggestion) {
        currentSuggestions.removeAll { $0.id == suggestion.id }
        if currentSuggestions.isEmpty {
            hideSuggestions()
        }
    }

    // MARK: - Idle Timer Management

    func startIdleTimer(onIdle: @escaping () -> Void) {
        stopIdleTimer()
        randomizeIdleThreshold()

        idleTimer = Timer.scheduledTimer(withTimeInterval: currentIdleThreshold, repeats: false) { _ in
            DispatchQueue.main.async {
                onIdle()
            }
        }
    }

    func resetIdleTimer(onIdle: @escaping () -> Void) {
        startIdleTimer(onIdle: onIdle)
    }

    func stopIdleTimer() {
        idleTimer?.invalidate()
        idleTimer = nil
    }

    // MARK: - Private Helpers

    private func randomizeIdleThreshold() {
        currentIdleThreshold = Double.random(in: minIdleTime...maxIdleTime)
    }
}

// MARK: - Array Extension

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
