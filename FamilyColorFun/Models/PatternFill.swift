import SwiftUI

// MARK: - Pattern Type

enum PatternType: String, Codable, CaseIterable, Identifiable {
    case polkaDots
    case stripes
    case zigzag
    case hearts
    case stars
    case checkers

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .polkaDots: return "Polka Dots"
        case .stripes: return "Stripes"
        case .zigzag: return "Zigzag"
        case .hearts: return "Hearts"
        case .stars: return "Stars"
        case .checkers: return "Checkers"
        }
    }

    var iconName: String {
        switch self {
        case .polkaDots: return "circle.grid.3x3.fill"
        case .stripes: return "line.3.horizontal"
        case .zigzag: return "waveform.path"
        case .hearts: return "heart.fill"
        case .stars: return "star.fill"
        case .checkers: return "square.grid.2x2.fill"
        }
    }
}

// MARK: - Pattern Fill Definition

struct PatternFill: Codable, Identifiable, Hashable {
    let id: String
    let type: PatternType
    let unlockRequirement: PatternUnlockRequirement

    var displayName: String { type.displayName }

    enum PatternUnlockRequirement: Codable, Hashable {
        case starCount(Int)
        case pagesCompleted(Int)
        case categoryComplete(String)
        case streak(Int)
    }
}

// MARK: - Default Patterns

extension PatternFill {
    static let allPatterns: [PatternFill] = [
        PatternFill(id: "polkaDots", type: .polkaDots, unlockRequirement: .starCount(15)),
        PatternFill(id: "stripes", type: .stripes, unlockRequirement: .pagesCompleted(10)),
        PatternFill(id: "zigzag", type: .zigzag, unlockRequirement: .starCount(30)),
        PatternFill(id: "hearts", type: .hearts, unlockRequirement: .streak(14)),
        PatternFill(id: "stars", type: .stars, unlockRequirement: .categoryComplete("animals")),
        PatternFill(id: "checkers", type: .checkers, unlockRequirement: .starCount(75)),
    ]

    static func pattern(byId id: String) -> PatternFill? {
        allPatterns.first { $0.id == id }
    }
}

// MARK: - Pattern Fill Store

final class PatternFillStore: ObservableObject {
    static let shared = PatternFillStore()

    @Published private(set) var unlockedIds: Set<String> = []

    private let storageKey = "pattern_fills_unlocked"

    private init() {
        load()
        checkUnlocks()
        setupObservers()
    }

    func isUnlocked(_ patternId: String) -> Bool {
        unlockedIds.contains(patternId)
    }

    func unlock(_ patternId: String) {
        guard !unlockedIds.contains(patternId) else { return }
        unlockedIds.insert(patternId)
        save()

        NotificationCenter.default.post(name: .rewardUnlocked, object: nil, userInfo: [
            "type": "patternFill",
            "id": patternId
        ])
    }

    func checkUnlocks() {
        let progression = ProgressionEngine.shared
        let totalCompleted = progression.completedPages.count

        for pattern in PatternFill.allPatterns {
            guard !unlockedIds.contains(pattern.id) else { continue }

            var shouldUnlock = false

            switch pattern.unlockRequirement {
            case .starCount(let required):
                shouldUnlock = progression.stars >= required
            case .pagesCompleted(let required):
                shouldUnlock = totalCompleted >= required
            case .categoryComplete(let categoryId):
                if let category = Category.all.first(where: { $0.categoryId == categoryId }) {
                    shouldUnlock = progression.isCategoryComplete(categoryId, totalPages: category.pages.count)
                } else {
                    #if DEBUG
                    print("⚠️ PatternFillStore: Category '\(categoryId)' not found for unlock requirement")
                    #endif
                }
            case .streak(let required):
                shouldUnlock = progression.streak >= required
            }

            if shouldUnlock {
                unlock(pattern.id)
            }
        }
    }

    var unlockedPatterns: [PatternFill] {
        PatternFill.allPatterns.filter { unlockedIds.contains($0.id) }
    }

    private var cancellables = Set<AnyCancellable>()

    private func setupObservers() {
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

    private func save() {
        let array = Array(unlockedIds)
        if let data = try? JSONEncoder().encode(array) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            unlockedIds = Set(decoded)
        }
    }

    #if DEBUG
    func resetForTesting() {
        unlockedIds = []
        save()
    }
    #endif
}

import Combine

// MARK: - Pattern View (for rendering patterns)

struct PatternView: View {
    let pattern: PatternType
    let baseColor: Color
    let patternColor: Color
    let size: CGSize

    var body: some View {
        Canvas { context, canvasSize in
            // Fill background with base color
            context.fill(
                Path(CGRect(origin: .zero, size: canvasSize)),
                with: .color(baseColor)
            )

            // Draw pattern
            switch pattern {
            case .polkaDots:
                drawPolkaDots(context: context, size: canvasSize)
            case .stripes:
                drawStripes(context: context, size: canvasSize)
            case .zigzag:
                drawZigzag(context: context, size: canvasSize)
            case .hearts:
                drawHearts(context: context, size: canvasSize)
            case .stars:
                drawStars(context: context, size: canvasSize)
            case .checkers:
                drawCheckers(context: context, size: canvasSize)
            }
        }
        .frame(width: size.width, height: size.height)
    }

    private func drawPolkaDots(context: GraphicsContext, size: CGSize) {
        let dotSize: CGFloat = 8
        let spacing: CGFloat = 20
        var y: CGFloat = spacing / 2

        var rowOffset = false
        while y < size.height {
            var x: CGFloat = rowOffset ? spacing : spacing / 2
            while x < size.width {
                let rect = CGRect(x: x - dotSize/2, y: y - dotSize/2, width: dotSize, height: dotSize)
                context.fill(Path(ellipseIn: rect), with: .color(patternColor))
                x += spacing
            }
            y += spacing * 0.866 // Hexagonal packing
            rowOffset.toggle()
        }
    }

    private func drawStripes(context: GraphicsContext, size: CGSize) {
        let stripeWidth: CGFloat = 10
        var x: CGFloat = 0
        var isPattern = false

        while x < size.width + size.height {
            if isPattern {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x - size.height, y: size.height))
                path.addLine(to: CGPoint(x: x - size.height + stripeWidth, y: size.height))
                path.addLine(to: CGPoint(x: x + stripeWidth, y: 0))
                path.closeSubpath()
                context.fill(path, with: .color(patternColor))
            }
            x += stripeWidth
            isPattern.toggle()
        }
    }

    private func drawZigzag(context: GraphicsContext, size: CGSize) {
        let amplitude: CGFloat = 10
        let wavelength: CGFloat = 20
        var y: CGFloat = amplitude

        while y < size.height {
            var path = Path()
            path.move(to: CGPoint(x: 0, y: y))

            var x: CGFloat = 0
            var up = true
            while x < size.width {
                let nextX = x + wavelength / 2
                let nextY = up ? y - amplitude : y + amplitude
                path.addLine(to: CGPoint(x: nextX, y: nextY))
                x = nextX
                up.toggle()
            }

            context.stroke(path, with: .color(patternColor), lineWidth: 2)
            y += amplitude * 3
        }
    }

    private func drawHearts(context: GraphicsContext, size: CGSize) {
        let heartSize: CGFloat = 12
        let spacing: CGFloat = 25

        var y: CGFloat = spacing / 2
        while y < size.height {
            var x: CGFloat = spacing / 2
            while x < size.width {
                drawHeart(context: context, center: CGPoint(x: x, y: y), size: heartSize)
                x += spacing
            }
            y += spacing
        }
    }

    private func drawHeart(context: GraphicsContext, center: CGPoint, size: CGFloat) {
        var path = Path()
        let s = size / 2

        path.move(to: CGPoint(x: center.x, y: center.y + s * 0.6))
        path.addCurve(
            to: CGPoint(x: center.x - s, y: center.y - s * 0.2),
            control1: CGPoint(x: center.x - s * 0.5, y: center.y + s * 0.6),
            control2: CGPoint(x: center.x - s, y: center.y + s * 0.2)
        )
        path.addCurve(
            to: CGPoint(x: center.x, y: center.y - s * 0.4),
            control1: CGPoint(x: center.x - s, y: center.y - s * 0.6),
            control2: CGPoint(x: center.x - s * 0.3, y: center.y - s * 0.6)
        )
        path.addCurve(
            to: CGPoint(x: center.x + s, y: center.y - s * 0.2),
            control1: CGPoint(x: center.x + s * 0.3, y: center.y - s * 0.6),
            control2: CGPoint(x: center.x + s, y: center.y - s * 0.6)
        )
        path.addCurve(
            to: CGPoint(x: center.x, y: center.y + s * 0.6),
            control1: CGPoint(x: center.x + s, y: center.y + s * 0.2),
            control2: CGPoint(x: center.x + s * 0.5, y: center.y + s * 0.6)
        )

        context.fill(path, with: .color(patternColor))
    }

    private func drawStars(context: GraphicsContext, size: CGSize) {
        let starSize: CGFloat = 10
        let spacing: CGFloat = 25

        var y: CGFloat = spacing / 2
        while y < size.height {
            var x: CGFloat = spacing / 2
            while x < size.width {
                drawStar(context: context, center: CGPoint(x: x, y: y), size: starSize)
                x += spacing
            }
            y += spacing
        }
    }

    private func drawStar(context: GraphicsContext, center: CGPoint, size: CGFloat) {
        var path = Path()
        let points = 5
        let innerRadius = size * 0.4
        let outerRadius = size

        for i in 0..<(points * 2) {
            let angle = Double(i) * .pi / Double(points) - .pi / 2
            let radius = i % 2 == 0 ? outerRadius : innerRadius
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius,
                y: center.y + CGFloat(sin(angle)) * radius
            )
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        context.fill(path, with: .color(patternColor))
    }

    private func drawCheckers(context: GraphicsContext, size: CGSize) {
        let squareSize: CGFloat = 15
        var y: CGFloat = 0
        var rowStart = false

        while y < size.height {
            var x: CGFloat = rowStart ? squareSize : 0
            while x < size.width {
                let rect = CGRect(x: x, y: y, width: squareSize, height: squareSize)
                context.fill(Path(rect), with: .color(patternColor))
                x += squareSize * 2
            }
            y += squareSize
            rowStart.toggle()
        }
    }
}

// MARK: - Pattern Picker

struct PatternPicker: View {
    let onSelect: (PatternFill, Color) -> Void
    let baseColor: Color

    @ObservedObject private var patternStore = PatternFillStore.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "square.grid.3x3")
                    .foregroundColor(.teal)
                Text("Patterns")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(PatternFill.allPatterns) { pattern in
                        PatternCell(
                            pattern: pattern,
                            baseColor: baseColor,
                            isUnlocked: patternStore.isUnlocked(pattern.id),
                            onSelect: { onSelect(pattern, baseColor) }
                        )
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

private struct PatternCell: View {
    let pattern: PatternFill
    let baseColor: Color
    let isUnlocked: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: {
            if isUnlocked {
                onSelect()
                SoundManager.shared.playTap()
            }
        }) {
            ZStack {
                if isUnlocked {
                    PatternView(
                        pattern: pattern.type,
                        baseColor: baseColor,
                        patternColor: baseColor.opacity(0.3),
                        size: CGSize(width: 44, height: 44)
                    )
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                } else {
                    Circle()
                        .fill(Color(.systemGray4))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "lock.fill")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        )
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(!isUnlocked)
    }
}

// MARK: - Preview

#Preview("Pattern Picker") {
    VStack {
        PatternPicker(onSelect: { _, _ in }, baseColor: .blue)
        Spacer()
    }
    .background(Color(.systemGroupedBackground))
}
