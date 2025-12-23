import SwiftUI
import UIKit

struct TapFillCanvas: View {
    let pageImage: UIImage
    @Binding var selectedColor: Color
    @ObservedObject var fillEngine: FillEngine
    @Binding var externalScale: CGFloat
    @Binding var externalOffset: CGSize

    @State private var cursorPosition: CGPoint? = nil
    @State private var isHovering = false

    init(pageImage: UIImage, selectedColor: Binding<Color>, fillEngine: FillEngine, externalScale: Binding<CGFloat> = .constant(1.0), externalOffset: Binding<CGSize> = .constant(.zero)) {
        self.pageImage = pageImage
        self._selectedColor = selectedColor
        self.fillEngine = fillEngine
        self._externalScale = externalScale
        self._externalOffset = externalOffset
    }

    var body: some View {
        GeometryReader { geometry in
            let imageSize = calculateFitSize(for: pageImage.size, in: geometry.size)

            ZStack {
                Color.white

                Image(uiImage: fillEngine.currentImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: imageSize.width, height: imageSize.height)
                    .scaleEffect(externalScale)
                    .offset(externalOffset)
                    .gesture(tapGesture(imageSize: imageSize, containerSize: geometry.size))
                    .gesture(magnificationGesture)
                    .onContinuousHover { phase in
                        switch phase {
                        case .active(let location):
                            cursorPosition = location
                            isHovering = true
                        case .ended:
                            isHovering = false
                        }
                    }

                // Brush cursor indicator
                if let position = cursorPosition, isHovering {
                    BrushCursor(color: selectedColor)
                        .position(position)
                        .allowsHitTesting(false)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .clipped()
    }

    private func calculateFitSize(for imageSize: CGSize, in containerSize: CGSize) -> CGSize {
        let widthRatio = containerSize.width / imageSize.width
        let heightRatio = containerSize.height / imageSize.height
        let ratio = min(widthRatio, heightRatio)
        return CGSize(width: imageSize.width * ratio, height: imageSize.height * ratio)
    }

    private func tapGesture(imageSize: CGSize, containerSize: CGSize) -> some Gesture {
        SpatialTapGesture()
            .onEnded { value in
                // Gesture is attached to Image view, so value.location is already in Image's coordinate space
                // Only need to account for scale transform (no imageOrigin subtraction needed)
                let tapInImage = CGPoint(
                    x: value.location.x / externalScale,
                    y: value.location.y / externalScale
                )

                let normalizedPoint = CGPoint(
                    x: tapInImage.x / imageSize.width,
                    y: tapInImage.y / imageSize.height
                )

                guard normalizedPoint.x >= 0, normalizedPoint.x <= 1,
                      normalizedPoint.y >= 0, normalizedPoint.y <= 1 else { return }

                fillEngine.fill(at: normalizedPoint, with: UIColor(selectedColor))
                SoundManager.shared.playFill()
            }
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                externalScale = min(max(value, 1.0), 3.0)
            }
            .onEnded { _ in
                withAnimation(.spring()) {
                    if externalScale < 1.2 {
                        externalScale = 1.0
                        externalOffset = .zero
                    }
                }
            }
    }
}

// MARK: - Fill Engine (Label-Map Based)
class FillEngine: ObservableObject {
    @Published private(set) var currentImage: UIImage
    @Published private(set) var progress: Double = 0
    @Published private(set) var canUndo: Bool = false
    @Published private(set) var filledRegions: Set<Int> = []
    @Published private(set) var regionProgress: Int = 0
    @Published private(set) var regionColors: [Int: Int] = [:] // regionId -> paletteIndex

    let metadata: ColoringPageMetadata?
    private let originalImage: UIImage
    private var undoStack: [(UIImage, Set<Int>, [Int: Int])] = []
    private let maxUndoSteps = 10

    // Label-map cache for O(1) hit testing
    // Supports both grayscale (legacy, 8-bit, max 255 regions) and
    // RGB24 encoding (new, supports 16M+ regions: regionId = R + G*256 + B*65536)
    private var labelMapBuffer: [UInt8] = []
    private var labelMapWidth: Int = 0
    private var labelMapHeight: Int = 0
    private var labelMapBytesPerPixel: Int = 1  // 1 = grayscale, 4 = RGBA
    private var hasLabelMap: Bool = false

    init(image: UIImage, metadata: ColoringPageMetadata? = nil, labelMap: UIImage? = nil) {
        self.originalImage = image
        self.currentImage = image
        self.metadata = metadata

        if let labelMap = labelMap {
            cacheLabelMap(labelMap)
        }
    }

    /// Cache label-map raw bytes for O(1) lookup
    /// Supports both grayscale (legacy) and RGB24 encoding
    private func cacheLabelMap(_ labelMap: UIImage) {
        guard let cgImage = labelMap.cgImage else { return }

        labelMapWidth = cgImage.width
        labelMapHeight = cgImage.height

        // Detect encoding type from metadata or image format
        let isRGB = metadata?.labelEncoding == "rgb24" ||
                    cgImage.colorSpace?.model == .rgb

        if isRGB {
            // RGB24 encoding: Use RGBA format for easier access
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let bytesPerPixel = 4
            var buffer = [UInt8](repeating: 0, count: labelMapWidth * labelMapHeight * bytesPerPixel)

            guard let context = CGContext(
                data: &buffer,
                width: labelMapWidth,
                height: labelMapHeight,
                bitsPerComponent: 8,
                bytesPerRow: labelMapWidth * bytesPerPixel,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return }

            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: labelMapWidth, height: labelMapHeight))
            labelMapBuffer = buffer
            labelMapBytesPerPixel = bytesPerPixel
        } else {
            // Legacy grayscale encoding
            let colorSpace = CGColorSpaceCreateDeviceGray()
            var buffer = [UInt8](repeating: 0, count: labelMapWidth * labelMapHeight)

            guard let context = CGContext(
                data: &buffer,
                width: labelMapWidth,
                height: labelMapHeight,
                bitsPerComponent: 8,
                bytesPerRow: labelMapWidth,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.none.rawValue
            ) else { return }

            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: labelMapWidth, height: labelMapHeight))
            labelMapBuffer = buffer
            labelMapBytesPerPixel = 1
        }

        hasLabelMap = true
    }

    /// O(1) hit test: read pixel from cached buffer
    /// Supports both grayscale and RGB24 encoding
    func regionId(at imagePoint: CGPoint) -> Int? {
        guard hasLabelMap else { return nil }

        let x = Int(imagePoint.x)
        let y = Int(imagePoint.y)
        guard x >= 0, x < labelMapWidth, y >= 0, y < labelMapHeight else { return nil }

        if labelMapBytesPerPixel == 1 {
            // Grayscale: direct pixel value
            let index = y * labelMapWidth + x
            let pixelValue = Int(labelMapBuffer[index])
            return pixelValue > 0 ? pixelValue : nil
        } else {
            // RGB24: regionId = R + (G * 256) + (B * 65536)
            let pixelIndex = (y * labelMapWidth + x) * labelMapBytesPerPixel
            let r = Int(labelMapBuffer[pixelIndex])
            let g = Int(labelMapBuffer[pixelIndex + 1])
            let b = Int(labelMapBuffer[pixelIndex + 2])

            let regionId = r + (g * 256) + (b * 65536)
            return regionId > 0 ? regionId : nil  // 0 = background
        }
    }

    /// Fill using label-map mask if available, otherwise fall back to flood fill
    func fill(at normalizedPoint: CGPoint, with color: UIColor, paletteIndex: Int = 0) {
        let pixelPoint = CGPoint(
            x: normalizedPoint.x * currentImage.size.width,
            y: normalizedPoint.y * currentImage.size.height
        )

        // Try label-map based fill first
        if hasLabelMap, let regionId = regionId(at: pixelPoint) {
            // Allow re-filling with different color
            if let filled = FloodFillService.applyMaskFill(
                image: currentImage,
                labelMapBuffer: labelMapBuffer,
                width: labelMapWidth,
                height: labelMapHeight,
                regionId: regionId,
                color: color
            ) {
                pushUndo()
                currentImage = filled
                filledRegions.insert(regionId)
                regionColors[regionId] = paletteIndex
                regionProgress = filledRegions.count
                updateProgress()
                return
            }
        }

        // Fallback to traditional flood fill
        guard let filled = FloodFillService.floodFill(
            image: currentImage,
            at: pixelPoint,
            with: color
        ) else { return }

        pushUndo()
        currentImage = filled
        updateProgress()
    }

    /// Get next unfilled region (LARGEST first = easier tap targets for kids)
    var nextUnfilledRegion: RegionMetadata? {
        guard let regions = metadata?.regions else { return nil }
        return regions
            .filter { !filledRegions.contains($0.id) }
            .sorted { $0.pixelCount > $1.pixelCount } // Largest first
            .first
    }

    /// Get nearest unfilled regions to a point
    func nearestUnfilled(to point: CGPoint, limit: Int = 3) -> [RegionMetadata] {
        guard let regions = metadata?.regions else { return [] }
        return Array(
            regions
                .filter { !filledRegions.contains($0.id) }
                .sorted { distance($0.centroid, point) < distance($1.centroid, point) }
                .prefix(limit)
        )
    }

    private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        hypot(a.x - b.x, a.y - b.y)
    }

    /// Fill all remaining unfilled regions with random colors from palette
    func fillAllRemaining(palette: [Color]) {
        guard let metadata = metadata else { return }
        let unfilled = metadata.regions.filter { !filledRegions.contains($0.id) }

        for region in unfilled {
            let normalizedPoint = CGPoint(
                x: region.centroid.x / metadata.imageSize.width,
                y: region.centroid.y / metadata.imageSize.height
            )
            let randomColor = palette.randomElement() ?? .blue
            let paletteIndex = palette.firstIndex(of: randomColor) ?? 0
            fill(at: normalizedPoint, with: UIColor(randomColor), paletteIndex: paletteIndex)
        }
    }

    func undo() {
        guard let (previous, prevFilled, prevColors) = undoStack.popLast() else { return }
        currentImage = previous
        filledRegions = prevFilled
        regionColors = prevColors
        regionProgress = filledRegions.count
        canUndo = !undoStack.isEmpty
        updateProgress()
    }

    func clear() {
        pushUndo()
        currentImage = originalImage
        filledRegions.removeAll()
        regionColors.removeAll()
        regionProgress = 0
        updateProgress()
    }

    private func pushUndo() {
        undoStack.append((currentImage, filledRegions, regionColors))
        if undoStack.count > maxUndoSteps {
            undoStack.removeFirst()
        }
        canUndo = true
    }

    private func updateProgress() {
        if let total = metadata?.totalRegions, total > 0 {
            progress = Double(regionProgress) / Double(total)
        } else {
            progress = FloodFillService.calculateProgress(for: currentImage)
        }
    }
}

// MARK: - Brush Cursor
struct BrushCursor: View {
    let color: Color

    var body: some View {
        ZStack {
            // Paint bucket icon
            Image(systemName: "paintbrush.pointed.fill")
                .font(.system(size: 28))
                .foregroundStyle(color)
                .shadow(color: .black.opacity(0.3), radius: 1, x: 1, y: 1)
                .rotationEffect(.degrees(-45))
                .offset(x: 10, y: 10)

            // Crosshair for precision
            Circle()
                .stroke(Color.black, lineWidth: 1.5)
                .frame(width: 12, height: 12)

            Circle()
                .stroke(Color.white, lineWidth: 1)
                .frame(width: 10, height: 10)

            Circle()
                .fill(color)
                .frame(width: 4, height: 4)
        }
    }
}
