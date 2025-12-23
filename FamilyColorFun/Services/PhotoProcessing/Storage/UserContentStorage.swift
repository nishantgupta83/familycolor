import UIKit

/// Manages storage for user-generated coloring pages
final class UserContentStorage {
    static let shared = UserContentStorage()

    private let fileManager = FileManager.default
    private let userContentDir: URL
    private let pagesKey = "userGeneratedPages"

    private init() {
        let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        userContentDir = documentsDir.appendingPathComponent("UserContent", isDirectory: true)

        // Create directory if needed
        try? fileManager.createDirectory(at: userContentDir, withIntermediateDirectories: true)
    }

    // MARK: - Save

    /// Save a user-generated coloring page
    func save(lineArt: UIImage, originalPhoto: UIImage?, name: String, preset: LineArtPreset) throws -> UserGeneratedPage {
        let pageId = UUID()
        let pageDir = userContentDir.appendingPathComponent(pageId.uuidString)
        try fileManager.createDirectory(at: pageDir, withIntermediateDirectories: true)

        // Save line art
        let lineArtPath = pageDir.appendingPathComponent("line_art.png")
        guard let lineArtData = lineArt.pngData() else {
            throw StorageError.saveFailed
        }
        try lineArtData.write(to: lineArtPath)

        // Save original photo if provided
        var originalPath: String? = nil
        if let photo = originalPhoto {
            let photoPath = pageDir.appendingPathComponent("original.jpg")
            if let photoData = photo.jpegData(compressionQuality: 0.8) {
                try photoData.write(to: photoPath)
                originalPath = photoPath.path
            }
        }

        let page = UserGeneratedPage(
            id: pageId,
            name: name,
            preset: preset,
            lineArtPath: lineArtPath.path,
            originalPhotoPath: originalPath
        )

        // Save to list
        var pages = loadAllPages()
        pages.append(page)
        savePagesMetadata(pages)

        return page
    }

    // MARK: - Load

    /// Load all user-generated pages
    func loadAllPages() -> [UserGeneratedPage] {
        guard let data = UserDefaults.standard.data(forKey: pagesKey),
              let pages = try? JSONDecoder().decode([UserGeneratedPage].self, from: data) else {
            return []
        }
        return pages
    }

    /// Load line art image for a page
    func loadLineArt(for page: UserGeneratedPage) -> UIImage? {
        return UIImage(contentsOfFile: page.lineArtPath)
    }

    /// Load original photo for a page
    func loadOriginalPhoto(for page: UserGeneratedPage) -> UIImage? {
        guard let path = page.originalPhotoPath else { return nil }
        return UIImage(contentsOfFile: path)
    }

    // MARK: - Delete

    /// Delete a user-generated page
    func delete(_ page: UserGeneratedPage) throws {
        let pageDir = userContentDir.appendingPathComponent(page.id.uuidString)
        try fileManager.removeItem(at: pageDir)

        var pages = loadAllPages()
        pages.removeAll { $0.id == page.id }
        savePagesMetadata(pages)
    }

    // MARK: - Private

    private func savePagesMetadata(_ pages: [UserGeneratedPage]) {
        if let data = try? JSONEncoder().encode(pages) {
            UserDefaults.standard.set(data, forKey: pagesKey)
        }
    }
}

enum StorageError: Error {
    case saveFailed
    case loadFailed
    case deleteFailed
}
