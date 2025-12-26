import SwiftUI

// MARK: - Metallic Color Picker

struct MetallicColorPicker: View {
    let onSelect: (MetallicColor) -> Void

    @ObservedObject private var metallicStore = MetallicColorStore.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.yellow)
                Text("Special Colors")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(MetallicColor.allMetallicColors) { metallic in
                        MetallicColorCell(
                            metallic: metallic,
                            isUnlocked: metallicStore.isUnlocked(metallic.id),
                            onSelect: { onSelect(metallic) }
                        )
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Metallic Color Cell

private struct MetallicColorCell: View {
    let metallic: MetallicColor
    let isUnlocked: Bool
    let onSelect: () -> Void

    @State private var animateShimmer = false

    var body: some View {
        Button(action: {
            if isUnlocked {
                onSelect()
                SoundManager.shared.playTap()
            }
        }) {
            ZStack {
                if isUnlocked {
                    // Shimmer effect for unlocked colors
                    Circle()
                        .fill(metallic.fillGradient)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.white.opacity(0.6), .clear],
                                        startPoint: animateShimmer ? .topLeading : .bottomTrailing,
                                        endPoint: animateShimmer ? .bottomTrailing : .topLeading
                                    )
                                )
                                .frame(width: 20, height: 20)
                                .offset(x: animateShimmer ? 12 : -12, y: animateShimmer ? 12 : -12)
                                .blur(radius: 4)
                        )
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .shadow(color: metallic.type.primaryColor.opacity(0.5), radius: 4)
                } else {
                    // Locked state
                    Circle()
                        .fill(Color(.systemGray4))
                        .frame(width: 44, height: 44)
                        .overlay(
                            VStack(spacing: 2) {
                                Image(systemName: "lock.fill")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        )
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(!isUnlocked)
        .onAppear {
            if isUnlocked {
                withAnimation(
                    .easeInOut(duration: 2)
                    .repeatForever(autoreverses: true)
                ) {
                    animateShimmer = true
                }
            }
        }
    }
}

// MARK: - Metallic Color Swatch (for showing selected metallic)

struct MetallicColorSwatch: View {
    let metallic: MetallicColor
    let size: CGFloat

    @State private var animateShimmer = false

    var body: some View {
        Circle()
            .fill(metallic.fillGradient)
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.4), .clear],
                            startPoint: animateShimmer ? .topLeading : .bottomTrailing,
                            endPoint: animateShimmer ? .bottomTrailing : .topLeading
                        )
                    )
                    .frame(width: size * 0.4, height: size * 0.4)
                    .offset(
                        x: animateShimmer ? size * 0.2 : -size * 0.2,
                        y: animateShimmer ? size * 0.2 : -size * 0.2
                    )
                    .blur(radius: size * 0.1)
            )
            .clipShape(Circle())
            .shadow(color: metallic.type.primaryColor.opacity(0.4), radius: 3)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 2)
                    .repeatForever(autoreverses: true)
                ) {
                    animateShimmer = true
                }
            }
    }
}

// MARK: - Unlock Requirement Display

struct MetallicUnlockRequirement: View {
    let metallic: MetallicColor

    var body: some View {
        HStack(spacing: 4) {
            switch metallic.unlockRequirement {
            case .starMilestone(let count):
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("\(count)")
            case .categoryComplete(let catId):
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Complete \(catId)")
            case .streak(let days):
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text("\(days) day streak")
            case .pagesCompleted(let count):
                Image(systemName: "paintpalette.fill")
                    .foregroundColor(.blue)
                Text("\(count) pages")
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}

// MARK: - Preview

#Preview("Metallic Picker") {
    VStack {
        MetallicColorPicker(onSelect: { _ in })
        Spacer()
    }
    .background(Color(.systemGroupedBackground))
}
