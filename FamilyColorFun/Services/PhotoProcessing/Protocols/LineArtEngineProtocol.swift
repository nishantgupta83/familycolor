import UIKit

/// Protocol for line art extraction engines
protocol LineArtEngineProtocol {
    /// Extract line art from a photo
    func extractLines(from photo: UIImage, settings: LineArtSettings) async throws -> UIImage

    /// Engine name for analytics/logging
    var engineName: String { get }

    /// Whether the engine is available on this device
    var isAvailable: Bool { get }
}
