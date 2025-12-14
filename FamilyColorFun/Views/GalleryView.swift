import SwiftUI

struct GalleryView: View {
    @StateObject private var storage = StorageService.shared

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            Group {
                if storage.artworks.isEmpty {
                    EmptyGalleryView()
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(storage.artworks) { artwork in
                                ArtworkCard(artwork: artwork)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("My Art")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

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

struct ArtworkCard: View {
    let artwork: Artwork
    @State private var image: UIImage?

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .aspectRatio(1, contentMode: .fit)

                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(4)
                } else {
                    ProgressView()
                }
            }
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

            Text(artwork.pageName)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)

            ProgressView(value: artwork.progress)
                .tint(.green)
                .scaleEffect(y: 0.5)
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

#Preview {
    GalleryView()
}
