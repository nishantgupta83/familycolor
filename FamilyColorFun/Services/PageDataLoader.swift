import Foundation

/// Errors that can occur when loading page data
enum PageDataError: Error, LocalizedError {
    case fileNotFound(String)
    case invalidJSON(String)
    case decodingFailed(String)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let filename):
            return "Could not find \(filename) in bundle"
        case .invalidJSON(let details):
            return "Invalid JSON format: \(details)"
        case .decodingFailed(let details):
            return "Failed to decode page data: \(details)"
        }
    }
}

/// Loads coloring page and category data from JSON
final class PageDataLoader {

    /// Shared instance for convenience
    static let shared = PageDataLoader()

    /// Cached data after first load
    private var cachedCategories: [CategoryData]?

    private init() {}

    // MARK: - Data Structures

    struct PageData: Codable {
        let name: String
        let imageName: String
    }

    struct CategoryData: Codable {
        let id: String
        let name: String
        let icon: String
        let pages: [PageData]
    }

    struct RootData: Codable {
        let categories: [CategoryData]
    }

    // MARK: - Public API

    /// Load all categories from JSON file
    /// - Returns: Array of CategoryData
    /// - Throws: PageDataError if loading fails
    func loadCategories() throws -> [CategoryData] {
        if let cached = cachedCategories {
            return cached
        }

        guard let url = Bundle.main.url(forResource: "pages", withExtension: "json") else {
            throw PageDataError.fileNotFound("pages.json")
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw PageDataError.fileNotFound("pages.json - \(error.localizedDescription)")
        }

        let decoder = JSONDecoder()
        let rootData: RootData
        do {
            rootData = try decoder.decode(RootData.self, from: data)
        } catch let decodingError as DecodingError {
            let details = describeDecodingError(decodingError)
            throw PageDataError.decodingFailed(details)
        } catch {
            throw PageDataError.invalidJSON(error.localizedDescription)
        }

        cachedCategories = rootData.categories
        return rootData.categories
    }

    /// Load pages for a specific category
    /// - Parameter categoryId: The category identifier
    /// - Returns: Array of PageData for the category
    func loadPages(forCategory categoryId: String) throws -> [PageData] {
        let categories = try loadCategories()
        guard let category = categories.first(where: { $0.id == categoryId }) else {
            return []
        }
        return category.pages
    }

    /// Clear cached data (useful for testing or refresh)
    func clearCache() {
        cachedCategories = nil
    }

    // MARK: - Private Helpers

    private func describeDecodingError(_ error: DecodingError) -> String {
        switch error {
        case .keyNotFound(let key, let context):
            return "Missing key '\(key.stringValue)' at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
        case .typeMismatch(let type, let context):
            return "Type mismatch for \(type) at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
        case .valueNotFound(let type, let context):
            return "Missing value of type \(type) at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
        case .dataCorrupted(let context):
            return "Corrupted data at \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
        @unknown default:
            return error.localizedDescription
        }
    }
}
