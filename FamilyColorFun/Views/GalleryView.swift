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

    var badgeInfo: (name: String, icon: String, color: Color) {
        switch totalArtworks {
        case 0..<3: return ("Beginner Artist", "star", .gray)
        case 3..<10: return ("Rising Star", "star.fill", .yellow)
        case 10..<25: return ("Color Champion", "trophy.fill", .orange)
        default: return ("Master Artist", "crown.fill", .purple)
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: badgeInfo.icon)
                .font(.title2)
                .foregroundStyle(badgeInfo.color)

            VStack(alignment: .leading, spacing: 2) {
                Text(badgeInfo.name)
                    .font(.headline)
                    .foregroundStyle(badgeInfo.color)
                Text("\(totalArtworks) masterpiece\(totalArtworks == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(badgeInfo.color.opacity(0.1))
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

    private var borderColor: Color {
        switch artwork.progress {
        case 1.0: return .green
        case 0.75..<1.0: return .yellow
        case 0.5..<0.75: return .orange
        default: return .gray.opacity(0.3)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Image section
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .aspectRatio(1, contentMode: .fit)

                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(6)
                } else {
                    ProgressView()
                }

                // Completion badge
                if artwork.progress >= 1.0 {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.seal.fill")
                                .font(.title3)
                                .foregroundStyle(.green)
                                .background(Circle().fill(.white).padding(-4))
                                .padding(8)
                        }
                        Spacer()
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 3)
            )
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)

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
