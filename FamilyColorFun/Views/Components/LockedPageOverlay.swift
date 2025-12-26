import SwiftUI

// MARK: - Locked Page Overlay (shown on thumbnails)

struct LockedPageOverlay: View {
    let unlockCost: Int

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.5)

            VStack(spacing: 4) {
                Image(systemName: "lock.fill")
                    .font(.title2)
                    .foregroundColor(.white)

                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                    Text("\(unlockCost)")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Unlock Sheet (shown when tapping locked page)

struct UnlockSheet: View {
    let pageName: String
    let unlockCost: Int
    let availableStars: Int
    let onUnlock: () -> Void
    let onDismiss: () -> Void
    let onAskParent: () -> Void

    var canAfford: Bool { availableStars >= unlockCost }

    var body: some View {
        VStack(spacing: 24) {
            // Lock icon with glow
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.orange, .yellow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "lock.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.white)
            }
            .shadow(color: .orange.opacity(0.4), radius: 12)

            // Title
            Text("Unlock This Page?")
                .font(.title2.bold())

            // Page name
            Text("\"\(pageName)\"")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Cost display
            HStack(spacing: 8) {
                Text("Costs")
                    .foregroundStyle(.secondary)
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("\(unlockCost)")
                        .font(.title2.bold())
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
            )

            // Current stars
            HStack(spacing: 4) {
                Text("You have")
                    .foregroundStyle(.secondary)
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("\(availableStars)")
                    .fontWeight(.semibold)
                Text("stars")
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)

            // Action buttons
            VStack(spacing: 12) {
                if canAfford {
                    Button {
                        onUnlock()
                    } label: {
                        HStack {
                            Image(systemName: "lock.open.fill")
                            Text("Unlock Now!")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                } else {
                    // Not enough stars
                    VStack(spacing: 8) {
                        Text("Need \(unlockCost - availableStars) more stars!")
                            .font(.subheadline)
                            .foregroundStyle(.orange)

                        Button {
                            onDismiss()
                        } label: {
                            HStack {
                                Image(systemName: "paintpalette.fill")
                                Text("Color more to earn stars!")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                }

                Button {
                    onAskParent()
                } label: {
                    Text("Ask a parent")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.regularMaterial)
        )
        .padding(.horizontal, 24)
    }
}

// MARK: - Preview

#Preview("Locked Overlay") {
    ZStack {
        Color.gray
        RoundedRectangle(cornerRadius: 12)
            .fill(.white)
            .frame(width: 100, height: 100)
            .overlay(
                LockedPageOverlay(unlockCost: 5)
            )
    }
}

#Preview("Unlock Sheet - Can Afford") {
    ZStack {
        Color.black.opacity(0.3)
        UnlockSheet(
            pageName: "Cute Lion",
            unlockCost: 5,
            availableStars: 10,
            onUnlock: {},
            onDismiss: {},
            onAskParent: {}
        )
    }
}

#Preview("Unlock Sheet - Cannot Afford") {
    ZStack {
        Color.black.opacity(0.3)
        UnlockSheet(
            pageName: "Cute Elephant",
            unlockCost: 5,
            availableStars: 2,
            onUnlock: {},
            onDismiss: {},
            onAskParent: {}
        )
    }
}
