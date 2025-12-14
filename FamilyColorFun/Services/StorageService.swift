import SwiftUI
import Foundation

class StorageService: ObservableObject {
    static let shared = StorageService()

    @Published var artworks: [Artwork] = []

    private let artworksKey = "saved_artworks"
    private let fileManager = FileManager.default

    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var artworksDirectory: URL {
        documentsDirectory.appendingPathComponent("Artworks", isDirectory: true)
    }

    private init() {
        createArtworksDirectoryIfNeeded()
        loadArtworks()
    }

    private func createArtworksDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: artworksDirectory.path) {
            try? fileManager.createDirectory(at: artworksDirectory, withIntermediateDirectories: true)
        }
    }

    // MARK: - Save/Load Artworks

    func saveArtwork(image: UIImage, page: ColoringPage, category: Category, progress: Double) -> Artwork? {
        let fileName = "\(UUID().uuidString).png"
        let filePath = artworksDirectory.appendingPathComponent(fileName)

        guard let data = image.pngData() else { return nil }

        do {
            try data.write(to: filePath)
            let artwork = Artwork(
                pageId: page.id,
                pageName: page.name,
                categoryName: category.name,
                imagePath: fileName,
                progress: progress
            )

            artworks.insert(artwork, at: 0)
            saveArtworksList()
            return artwork
        } catch {
            print("Failed to save artwork: \(error)")
            return nil
        }
    }

    func loadImage(from fileName: String) -> UIImage? {
        let filePath = artworksDirectory.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: filePath) else { return nil }
        return UIImage(data: data)
    }

    func deleteArtwork(_ artwork: Artwork) {
        let filePath = artworksDirectory.appendingPathComponent(artwork.imagePath)
        try? fileManager.removeItem(at: filePath)

        artworks.removeAll { $0.id == artwork.id }
        saveArtworksList()
    }

    private func loadArtworks() {
        guard let data = UserDefaults.standard.data(forKey: artworksKey),
              let decoded = try? JSONDecoder().decode([Artwork].self, from: data) else {
            return
        }
        artworks = decoded
    }

    private func saveArtworksList() {
        guard let data = try? JSONEncoder().encode(artworks) else { return }
        UserDefaults.standard.set(data, forKey: artworksKey)
    }

    // MARK: - Export

    func exportToPhotos(image: UIImage, completion: @escaping (Bool) -> Void) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        completion(true)
    }
}
