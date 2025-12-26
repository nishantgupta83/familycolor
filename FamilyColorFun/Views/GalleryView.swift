import SwiftUI
import UIKit

struct GalleryView: View {
    @StateObject private var storage = StorageService.shared
    @State private var selectedArtwork: Artwork?
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?
    @State private var showDeleteConfirmation = false
    @State private var artworkToDelete: Artwork?

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            Group {
                if storage.artworks.isEmpty {
                    EmptyGalleryView()
                } else {
                    ScrollView {
                        // Header with badge
                        GalleryHeader(totalArtworks: storage.artworks.count)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)

                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(storage.artworks) { artwork in
                                ArtworkCard(
                                    artwork: artwork,
                                    onShare: { shareArtwork(artwork) },
                                    onPrint: { printArtwork(artwork) },
                                    onSave: { saveToPhotos(artwork) },
                                    onEdit: { editArtwork(artwork) },
                                    onDelete: { confirmDelete(artwork) }
                                )
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("My Masterpieces")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showShareSheet) {
                if let image = shareImage {
                    ActivityShareSheet(items: [image])
                }
            }
            .confirmationDialog("Delete Artwork?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let artwork = artworkToDelete {
                        storage.deleteArtwork(artwork)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This cannot be undone.")
            }
        }
    }

    private func shareArtwork(_ artwork: Artwork) {
        if let image = StorageService.shared.loadImage(from: artwork.imagePath) {
            shareImage = image
            showShareSheet = true
        }
    }

    private func printArtwork(_ artwork: Artwork) {
        guard let image = StorageService.shared.loadImage(from: artwork.imagePath) else { return }
        let printController = UIPrintInteractionController.shared
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.outputType = .photo
        printInfo.jobName = artwork.pageName
        printController.printInfo = printInfo
        printController.printingItem = image
        printController.present(animated: true)
    }

    private func saveToPhotos(_ artwork: Artwork) {
        if let image = StorageService.shared.loadImage(from: artwork.imagePath) {
            StorageService.shared.exportToPhotos(image: image) { success in
                if success {
                    SoundManager.shared.playTap()
                }
            }
        }
    }

    private func editArtwork(_ artwork: Artwork) {
        // Navigate to canvas with this artwork loaded
        selectedArtwork = artwork
    }

    private func confirmDelete(_ artwork: Artwork) {
        artworkToDelete = artwork
        showDeleteConfirmation = true
    }
}

// MARK: - Gallery Header
struct GalleryHeader: View {
    let totalArtworks: Int

    var badgeInfo: (name: String, icon: String, color: Color, emoji: String) {
        switch totalArtworks {
        case 0..<3: return ("Beginner Artist", "star", .gray, "⭐")
        case 3..<10: return ("Rising Star", "star.fill", .yellow, "🌟")
        case 10..<25: return ("Color Champion", "trophy.fill", .orange, "🏆")
        default: return ("Master Artist", "crown.fill", .pink, "👑")
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Decorative stars
            Text("✨")
                .font(.title3)

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [badgeInfo.color, badgeInfo.color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)

                Text(badgeInfo.emoji)
                    .font(.title2)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(badgeInfo.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(badgeInfo.color)
                Text("\(totalArtworks) masterpiece\(totalArtworks == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // More decorations
            Text("🎨")
                .font(.title3)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [badgeInfo.color.opacity(0.15), badgeInfo.color.opacity(0.05)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(badgeInfo.color.opacity(0.3), lineWidth: 2)
        )
    }
}

// MARK: - Empty Gallery
struct EmptyGalleryView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "paintpalette")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("No artwork yet!")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Start coloring to fill your gallery")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Artwork Card
struct ArtworkCard: View {
    let artwork: Artwork
    let onShare: () -> Void
    let onPrint: () -> Void
    let onSave: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var image: UIImage?

    // Colorful frame colors based on progress
    private var frameColors: [Color] {
        switch artwork.progress {
        case 1.0: return [Color(hex: "56AB2F"), Color(hex: "A8E063")] // Green
        case 0.75..<1.0: return [Color(hex: "F7B733"), Color(hex: "FC4A1A")] // Orange-Yellow
        case 0.5..<0.75: return [Color(hex: "FF416C"), Color(hex: "FF4B2B")] // Pink-Red
        case 0.25..<0.5: return [Color(hex: "8E2DE2"), Color(hex: "4A00E0")] // Purple
        default: return [Color(hex: "2193B0"), Color(hex: "6DD5ED")] // Blue
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Image section with colorful frame
            ZStack {
                // Colorful frame background
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: frameColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .aspectRatio(1, contentMode: .fit)

                // White inner area
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white)
                    .padding(6)

                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .padding(10)
                } else {
                    ProgressView()
                }

                // Completion badge
                if artwork.progress >= 1.0 {
                    VStack {
                        HStack {
                            Spacer()
                            ZStack {
                                Circle()
                                    .fill(.white)
                                    .frame(width: 28, height: 28)
                                Text("⭐")
                                    .font(.system(size: 18))
                            }
                            .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                            .padding(6)
                        }
                        Spacer()
                    }
                }
            }
            .shadow(color: frameColors[0].opacity(0.4), radius: 6, y: 3)

            // Page name
            Text(artwork.pageName)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
                .padding(.top, 6)

            // Action buttons
            HStack(spacing: 0) {
                ActionButton(icon: "square.and.arrow.up", action: onShare)
                ActionButton(icon: "printer", action: onPrint)
                ActionButton(icon: "square.and.arrow.down", action: onSave)
            }
            .padding(.vertical, 6)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.top, 4)
        }
        .contextMenu {
            Button {
                onEdit()
            } label: {
                Label("Continue Coloring", systemImage: "pencil")
            }

            Button {
                onShare()
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }

            Button {
                onSave()
            } label: {
                Label("Save to Photos", systemImage: "photo")
            }

            Divider()

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .task {
            await loadImage()
        }
    }

    private func loadImage() async {
        let path = artwork.imagePath
        image = await Task.detached {
            StorageService.shared.loadImage(from: path)
        }.value
    }
}

// MARK: - Action Button
struct ActionButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: {
            action()
            SoundManager.shared.playTap()
        }) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .frame(height: 28)
        }
    }
}

// MARK: - Activity Share Sheet
struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    GalleryView()
}
