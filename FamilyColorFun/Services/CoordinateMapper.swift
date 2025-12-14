import Foundation
import CoreGraphics

/// Handles coordinate transformation between view space and image space.
/// Accounts for .aspectFit scaling, zoom, and pan offsets.
struct CoordinateMapper {
    let imageSize: CGSize          // Original image dimensions (e.g., 1024x1024)
    private(set) var baseScale: CGFloat = 1.0     // Scale to fit image in container
    private(set) var displayRect: CGRect = .zero  // Image rect after .aspectFit

    var zoomScale: CGFloat = 1.0
    var panOffset: CGPoint = .zero

    init(imageSize: CGSize) {
        self.imageSize = imageSize
    }

    /// Call when container size changes (from GeometryReader)
    mutating func updateForContainer(_ containerSize: CGSize) {
        guard imageSize.width > 0, imageSize.height > 0,
              containerSize.width > 0, containerSize.height > 0 else { return }

        // Calculate .aspectFit scale and position
        let widthRatio = containerSize.width / imageSize.width
        let heightRatio = containerSize.height / imageSize.height
        baseScale = min(widthRatio, heightRatio)

        let fittedWidth = imageSize.width * baseScale
        let fittedHeight = imageSize.height * baseScale
        let originX = (containerSize.width - fittedWidth) / 2
        let originY = (containerSize.height - fittedHeight) / 2

        displayRect = CGRect(x: originX, y: originY, width: fittedWidth, height: fittedHeight)
    }

    /// Convert view tap point to image pixel coordinates.
    /// Accounts for zoom and pan transforms.
    func viewToImage(_ viewPoint: CGPoint) -> CGPoint {
        // Remove pan offset first
        let unpanned = CGPoint(
            x: viewPoint.x - panOffset.x,
            y: viewPoint.y - panOffset.y
        )

        // Convert to image-local coordinates
        let totalScale = baseScale * zoomScale
        guard totalScale > 0 else { return .zero }

        let localX = (unpanned.x - displayRect.minX) / totalScale
        let localY = (unpanned.y - displayRect.minY) / totalScale

        return CGPoint(x: localX, y: localY)
    }

    /// Convert image pixel coordinates to view coordinates.
    /// Used for positioning hint overlays.
    func imageToView(_ imagePoint: CGPoint) -> CGPoint {
        let totalScale = baseScale * zoomScale
        let viewX = displayRect.minX + imagePoint.x * totalScale + panOffset.x
        let viewY = displayRect.minY + imagePoint.y * totalScale + panOffset.y
        return CGPoint(x: viewX, y: viewY)
    }

    /// Check if an image point is within valid bounds
    func isValidImagePoint(_ point: CGPoint) -> Bool {
        return point.x >= 0 && point.x < imageSize.width &&
               point.y >= 0 && point.y < imageSize.height
    }

    /// Convert a CGRect from image space to view space
    func imageRectToView(_ imageRect: CGRect) -> CGRect {
        let origin = imageToView(imageRect.origin)
        let totalScale = baseScale * zoomScale
        return CGRect(
            x: origin.x,
            y: origin.y,
            width: imageRect.width * totalScale,
            height: imageRect.height * totalScale
        )
    }
}
