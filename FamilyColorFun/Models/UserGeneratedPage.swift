import Foundation
import UIKit

/// A user-generated coloring page from a photo upload
struct UserGeneratedPage: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let createdAt: Date
    let preset: String
    let lineArtPath: String
    let originalPhotoPath: String?
    let labelMapPath: String?

    init(
        id: UUID = UUID(),
        name: String,
        preset: LineArtPreset = .portrait,
        lineArtPath: String,
        originalPhotoPath: String? = nil,
        labelMapPath: String? = nil
    ) {
        self.id = id
        self.name = name
        self.createdAt = Date()
        self.preset = preset.rawValue
        self.lineArtPath = lineArtPath
        self.originalPhotoPath = originalPhotoPath
        self.labelMapPath = labelMapPath
    }

    var imageName: String {
        "user_\(id.uuidString.prefix(8))"
    }
}

extension UserGeneratedPage {
    /// Convert to ColoringPage for use in the existing canvas system
    func toColoringPage() -> ColoringPage {
        ColoringPage(name: name, imageName: imageName)
    }
}
