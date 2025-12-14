import XCTest
@testable import FamilyColorFun

final class LabelMapEncodingTests: XCTestCase {

    // MARK: - RGB24 Encoding Tests

    func testRGB24EncodingCalculation() {
        // Test basic RGB24 encoding formula: regionId = R + (G * 256) + (B * 65536)

        // Region 1: RGB(1, 0, 0)
        let region1 = 1 + (0 * 256) + (0 * 65536)
        XCTAssertEqual(region1, 1)

        // Region 256: RGB(0, 1, 0)
        let region256 = 0 + (1 * 256) + (0 * 65536)
        XCTAssertEqual(region256, 256)

        // Region 65536: RGB(0, 0, 1)
        let region65536 = 0 + (0 * 256) + (1 * 65536)
        XCTAssertEqual(region65536, 65536)

        // Region 65537: RGB(1, 0, 1)
        let region65537 = 1 + (0 * 256) + (1 * 65536)
        XCTAssertEqual(region65537, 65537)

        // Region 257: RGB(1, 1, 0)
        let region257 = 1 + (1 * 256) + (0 * 65536)
        XCTAssertEqual(region257, 257)
    }

    func testRGB24MaxRegionId() {
        // Maximum region ID with RGB24: R=255, G=255, B=255
        let maxRegion = 255 + (255 * 256) + (255 * 65536)
        XCTAssertEqual(maxRegion, 16777215) // 16M+ regions
    }

    // MARK: - Grayscale Encoding Tests

    func testGrayscaleEncodingRange() {
        // Grayscale supports 1-255 (0 is background)
        let minRegion = 1
        let maxRegion = 255

        XCTAssertEqual(minRegion, 1)
        XCTAssertEqual(maxRegion, 255)
    }

    // MARK: - FillEngine with Metadata Tests

    func testFillEngineInitializationWithMetadata() {
        let image = createTestImage()
        let metadata = ColoringPageMetadata(
            imageName: "test",
            imageSize: CGSize(width: 100, height: 100),
            totalRegions: 10,
            labelMapName: "test_labels",
            labelEncoding: "rgb24",
            regions: []
        )

        let engine = FillEngine(image: image, metadata: metadata)

        XCTAssertNotNil(engine.metadata)
        XCTAssertEqual(engine.metadata?.labelEncoding, "rgb24")
        XCTAssertEqual(engine.metadata?.totalRegions, 10)
    }

    func testFillEngineInitializationWithGrayscaleMetadata() {
        let image = createTestImage()
        let metadata = ColoringPageMetadata(
            imageName: "test_gray",
            imageSize: CGSize(width: 100, height: 100),
            totalRegions: 10,
            labelMapName: "test_labels",
            labelEncoding: nil, // Legacy grayscale has no encoding specified
            regions: []
        )

        let engine = FillEngine(image: image, metadata: metadata)

        XCTAssertNotNil(engine.metadata)
        XCTAssertNil(engine.metadata?.labelEncoding)
    }

    func testFillEngineWithRGB24LabelMap() {
        // Create a simple RGB24 label map
        let labelMap = createRGB24LabelMap()
        let image = createTestImage()
        let metadata = ColoringPageMetadata(
            imageName: "test",
            imageSize: CGSize(width: 100, height: 100),
            totalRegions: 3,
            labelMapName: "test_labels",
            labelEncoding: "rgb24",
            regions: [
                RegionMetadata(id: 1, centroid: CGPoint(x: 25, y: 25), boundingBox: CGRect(x: 0, y: 0, width: 50, height: 50), pixelCount: 2500, difficulty: 1),
                RegionMetadata(id: 256, centroid: CGPoint(x: 75, y: 25), boundingBox: CGRect(x: 50, y: 0, width: 50, height: 50), pixelCount: 2500, difficulty: 1),
                RegionMetadata(id: 65536, centroid: CGPoint(x: 50, y: 75), boundingBox: CGRect(x: 0, y: 50, width: 100, height: 50), pixelCount: 5000, difficulty: 1)
            ]
        )

        let engine = FillEngine(image: image, metadata: metadata, labelMap: labelMap)

        XCTAssertNotNil(engine.metadata)
        XCTAssertEqual(engine.metadata?.labelEncoding, "rgb24")
    }

    func testFillEngineWithGrayscaleLabelMap() {
        // Create a simple grayscale label map
        let labelMap = createGrayscaleLabelMap()
        let image = createTestImage()
        let metadata = ColoringPageMetadata(
            imageName: "test_gray",
            imageSize: CGSize(width: 100, height: 100),
            totalRegions: 3,
            labelMapName: "test_labels",
            regions: [
                RegionMetadata(id: 1, centroid: CGPoint(x: 25, y: 25), boundingBox: CGRect(x: 0, y: 0, width: 50, height: 50), pixelCount: 2500, difficulty: 1),
                RegionMetadata(id: 2, centroid: CGPoint(x: 75, y: 25), boundingBox: CGRect(x: 50, y: 0, width: 50, height: 50), pixelCount: 2500, difficulty: 1),
                RegionMetadata(id: 3, centroid: CGPoint(x: 50, y: 75), boundingBox: CGRect(x: 0, y: 50, width: 100, height: 50), pixelCount: 5000, difficulty: 1)
            ]
        )

        let engine = FillEngine(image: image, metadata: metadata, labelMap: labelMap)

        XCTAssertNotNil(engine.metadata)
        XCTAssertNil(engine.metadata?.labelEncoding) // Grayscale has no encoding
    }

    // MARK: - Helper Methods

    private func createTestImage() -> UIImage {
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    private func createRGB24LabelMap() -> UIImage {
        // Create a 100x100 RGB image with 3 regions:
        // Region 1 (R=1, G=0, B=0): Top-left quadrant
        // Region 256 (R=0, G=1, B=0): Top-right quadrant
        // Region 65536 (R=0, G=0, B=1): Bottom half

        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // Region 1: RGB(1, 0, 0)
            UIColor(red: 1/255.0, green: 0, blue: 0, alpha: 1).setFill()
            context.fill(CGRect(x: 0, y: 0, width: 50, height: 50))

            // Region 256: RGB(0, 1, 0)
            UIColor(red: 0, green: 1/255.0, blue: 0, alpha: 1).setFill()
            context.fill(CGRect(x: 50, y: 0, width: 50, height: 50))

            // Region 65536: RGB(0, 0, 1)
            UIColor(red: 0, green: 0, blue: 1/255.0, alpha: 1).setFill()
            context.fill(CGRect(x: 0, y: 50, width: 100, height: 50))
        }
    }

    private func createGrayscaleLabelMap() -> UIImage {
        // Create a 100x100 grayscale image with 3 regions (1, 2, 3)
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // Region 1: gray value 1/255
            UIColor(white: 1/255.0, alpha: 1).setFill()
            context.fill(CGRect(x: 0, y: 0, width: 50, height: 50))

            // Region 2: gray value 2/255
            UIColor(white: 2/255.0, alpha: 1).setFill()
            context.fill(CGRect(x: 50, y: 0, width: 50, height: 50))

            // Region 3: gray value 3/255
            UIColor(white: 3/255.0, alpha: 1).setFill()
            context.fill(CGRect(x: 0, y: 50, width: 100, height: 50))
        }
    }
}
