import Foundation
import CoreGraphics
import UIKit

// MARK: - Region Metadata
struct RegionMetadata: Codable, Identifiable {
    let id: Int                 // Matches label-map pixel values (1, 2, 3...)
    let centroid: CGPoint       // Center point for hint overlays
    let boundingBox: CGRect     // For quick filtering/bounds checking
    let pixelCount: Int         // Size of region (for difficulty calc)
    let difficulty: Int         // 1 = easy (large), 2 = medium, 3 = hard (small)

    // Custom coding keys to match JSON format
    enum CodingKeys: String, CodingKey {
        case id, centroid, boundingBox, pixelCount, difficulty
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        pixelCount = try container.decode(Int.self, forKey: .pixelCount)
        difficulty = try container.decode(Int.self, forKey: .difficulty)

        // Decode centroid from {"x": ..., "y": ...}
        let centroidDict = try container.decode([String: Double].self, forKey: .centroid)
        centroid = CGPoint(x: centroidDict["x"] ?? 0, y: centroidDict["y"] ?? 0)

        // Decode boundingBox from {"x": ..., "y": ..., "width": ..., "height": ...}
        let boxDict = try container.decode([String: Double].self, forKey: .boundingBox)
        boundingBox = CGRect(
            x: boxDict["x"] ?? 0,
            y: boxDict["y"] ?? 0,
            width: boxDict["width"] ?? 0,
            height: boxDict["height"] ?? 0
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(pixelCount, forKey: .pixelCount)
        try container.encode(difficulty, forKey: .difficulty)
        try container.encode(["x": centroid.x, "y": centroid.y], forKey: .centroid)
        try container.encode([
            "x": boundingBox.origin.x,
            "y": boundingBox.origin.y,
            "width": boundingBox.width,
            "height": boundingBox.height
        ], forKey: .boundingBox)
    }

    init(id: Int, centroid: CGPoint, boundingBox: CGRect, pixelCount: Int, difficulty: Int) {
        self.id = id
        self.centroid = centroid
        self.boundingBox = boundingBox
        self.pixelCount = pixelCount
        self.difficulty = difficulty
    }
}

// MARK: - Coloring Page Metadata
struct ColoringPageMetadata: Codable {
    let imageName: String
    let imageSize: CGSize       // Original image dimensions (critical for coordinate mapping)
    let totalRegions: Int
    let labelMapName: String    // e.g., "house_cottage_labels"
    let labelEncoding: String?  // "rgb24" for new pages, nil/missing for legacy grayscale
    let regions: [RegionMetadata]

    enum CodingKeys: String, CodingKey {
        case imageName, imageSize, totalRegions, labelMapName, labelEncoding, regions
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        imageName = try container.decode(String.self, forKey: .imageName)
        totalRegions = try container.decode(Int.self, forKey: .totalRegions)
        labelMapName = try container.decode(String.self, forKey: .labelMapName)
        labelEncoding = try container.decodeIfPresent(String.self, forKey: .labelEncoding)
        regions = try container.decode([RegionMetadata].self, forKey: .regions)

        // Decode imageSize from {"width": ..., "height": ...}
        let sizeDict = try container.decode([String: Double].self, forKey: .imageSize)
        imageSize = CGSize(width: sizeDict["width"] ?? 0, height: sizeDict["height"] ?? 0)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(imageName, forKey: .imageName)
        try container.encode(totalRegions, forKey: .totalRegions)
        try container.encode(labelMapName, forKey: .labelMapName)
        try container.encodeIfPresent(labelEncoding, forKey: .labelEncoding)
        try container.encode(regions, forKey: .regions)
        try container.encode(["width": imageSize.width, "height": imageSize.height], forKey: .imageSize)
    }

    init(imageName: String, imageSize: CGSize, totalRegions: Int, labelMapName: String, labelEncoding: String? = nil, regions: [RegionMetadata]) {
        self.imageName = imageName
        self.imageSize = imageSize
        self.totalRegions = totalRegions
        self.labelMapName = labelMapName
        self.labelEncoding = labelEncoding
        self.regions = regions
    }

    // MARK: - Loading from Bundle
    static func load(for imageName: String) -> ColoringPageMetadata? {
        // Try loading from PageMetadata folder in bundle
        guard let url = Bundle.main.url(forResource: imageName, withExtension: "json", subdirectory: "PageMetadata") else {
            // Fallback: try loading from Assets catalog data set
            if let asset = NSDataAsset(name: "PageMetadata/\(imageName)") {
                return try? JSONDecoder().decode(ColoringPageMetadata.self, from: asset.data)
            }
            return nil
        }

        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(ColoringPageMetadata.self, from: data)
    }
}
