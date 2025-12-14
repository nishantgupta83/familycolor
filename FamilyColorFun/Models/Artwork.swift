import Foundation

struct Artwork: Identifiable, Codable {
    let id: UUID
    let pageId: UUID
    let pageName: String
    let categoryName: String
    let savedDate: Date
    let imagePath: String
    var progress: Double // 0.0 to 1.0

    init(pageId: UUID, pageName: String, categoryName: String, imagePath: String, progress: Double = 0.0) {
        self.id = UUID()
        self.pageId = pageId
        self.pageName = pageName
        self.categoryName = categoryName
        self.savedDate = Date()
        self.imagePath = imagePath
        self.progress = progress
    }
}
