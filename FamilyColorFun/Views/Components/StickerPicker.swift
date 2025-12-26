import SwiftUI

// MARK: - Sticker Picker

struct StickerPicker: View {
    let onSelect: (StickerDefinition) -> Void
    let onDismiss: () -> Void

    @ObservedObject private var stickerStore = StickerStore.shared
    @State private var selectedCategory: StickerDefinition.StickerCategory = .stars

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Stickers")
                    .font(.title2.bold())

                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()

            // Category tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(StickerDefinition.StickerCategory.allCases, id: \.self) { category in
                        CategoryTab(
                            category: category,
                            isSelected: selectedCategory == category,
                            onTap: { selectedCategory = category }
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 12)

            // Sticker grid
            let stickers = StickerDefinition.stickers(in: selectedCategory)
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(stickers) { sticker in
                    StickerCell(
                        sticker: sticker,
                        isUnlocked: stickerStore.isUnlocked(sticker.id),
                        onTap: {
                            if stickerStore.isUnlocked(sticker.id) {
                                onSelect(sticker)
                                SoundManager.shared.playTap()
                            }
                        }
                    )
                }
            }
            .padding()

            Spacer()
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Category Tab

private struct CategoryTab: View {
    let category: StickerDefinition.StickerCategory
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(category.rawValue)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.blue : Color(.systemGray5))
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Sticker Cell

private struct StickerCell: View {
    let sticker: StickerDefinition
    let isUnlocked: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .aspectRatio(1, contentMode: .fit)

                if isUnlocked {
                    // Try to load sticker image, fallback to SF Symbol
                    if let uiImage = UIImage(named: sticker.imageName) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(8)
                    } else {
                        // Placeholder based on category
                        stickerPlaceholder
                    }
                } else {
                    // Locked state
                    VStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.title3)
                            .foregroundColor(.gray)

                        unlockRequirementText
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(4)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isUnlocked ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
            )
            .opacity(isUnlocked ? 1 : 0.6)
        }
        .buttonStyle(.plain)
        .disabled(!isUnlocked)
    }

    @ViewBuilder
    private var stickerPlaceholder: some View {
        Image(systemName: placeholderIcon)
            .font(.system(size: 32))
            .foregroundColor(placeholderColor)
    }

    private var placeholderIcon: String {
        switch sticker.category {
        case .stars: return "star.fill"
        case .animals: return "hare.fill"
        case .hearts: return "heart.fill"
        case .rainbows: return "rainbow"
        case .crowns: return "crown.fill"
        case .trophies: return "trophy.fill"
        }
    }

    private var placeholderColor: Color {
        switch sticker.category {
        case .stars: return .yellow
        case .animals: return .brown
        case .hearts: return .red
        case .rainbows: return .pink
        case .crowns: return .orange
        case .trophies: return .yellow
        }
    }

    @ViewBuilder
    private var unlockRequirementText: some View {
        switch sticker.unlockRequirement {
        case .free:
            Text("Free")
        case .starCount(let count):
            HStack(spacing: 2) {
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundColor(.yellow)
                Text("\(count)")
            }
        case .pagesCompleted(let count):
            Text("\(count) pages")
        case .categoryComplete(let catId):
            Text("Complete \(catId)")
        }
    }
}

// MARK: - Sticker Overlay View (for placed stickers on canvas)

struct StickerOverlayView: View {
    let placedStickers: [PlacedSticker]
    let canvasSize: CGSize
    let onRemove: ((UUID) -> Void)?

    var body: some View {
        ZStack {
            ForEach(placedStickers) { placed in
                if let definition = StickerDefinition.sticker(byId: placed.stickerId) {
                    PlacedStickerView(
                        placed: placed,
                        definition: definition,
                        canvasSize: canvasSize,
                        onRemove: onRemove
                    )
                }
            }
        }
    }
}

// MARK: - Placed Sticker View

private struct PlacedStickerView: View {
    let placed: PlacedSticker
    let definition: StickerDefinition
    let canvasSize: CGSize
    let onRemove: ((UUID) -> Void)?

    @State private var showDeleteButton = false

    private var position: CGPoint {
        CGPoint(
            x: placed.x * canvasSize.width,
            y: placed.y * canvasSize.height
        )
    }

    var body: some View {
        ZStack {
            stickerImage
                .scaleEffect(placed.scale)
                .rotationEffect(.degrees(placed.rotation))
        }
        .position(position)
        .onTapGesture {
            showDeleteButton.toggle()
        }
        .overlay(alignment: .topTrailing) {
            if showDeleteButton, let onRemove = onRemove {
                Button {
                    onRemove(placed.id)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.red)
                        .background(Circle().fill(.white))
                }
                .position(x: position.x + 20, y: position.y - 20)
            }
        }
    }

    @ViewBuilder
    private var stickerImage: some View {
        if let uiImage = UIImage(named: definition.imageName) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
        } else {
            Image(systemName: stickerIcon)
                .font(.system(size: 40))
                .foregroundColor(stickerColor)
        }
    }

    private var stickerIcon: String {
        switch definition.category {
        case .stars: return "star.fill"
        case .animals: return "hare.fill"
        case .hearts: return "heart.fill"
        case .rainbows: return "rainbow"
        case .crowns: return "crown.fill"
        case .trophies: return "trophy.fill"
        }
    }

    private var stickerColor: Color {
        switch definition.category {
        case .stars: return .yellow
        case .animals: return .brown
        case .hearts: return .red
        case .rainbows: return .pink
        case .crowns: return .orange
        case .trophies: return .yellow
        }
    }
}

// MARK: - Preview

#Preview("Sticker Picker") {
    StickerPicker(
        onSelect: { _ in },
        onDismiss: { }
    )
}
