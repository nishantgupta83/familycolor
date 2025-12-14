import XCTest
@testable import FamilyColorFun

final class PerformanceTests: XCTestCase {

    // MARK: - Flood Fill Performance

    func testFloodFillPerformanceSmallImage() throws {
        let image = createTestImage(size: CGSize(width: 256, height: 256))

        measure {
            _ = FloodFillService.floodFill(
                image: image,
                at: CGPoint(x: 128, y: 128),
                with: .red
            )
        }
    }

    func testFloodFillPerformanceMediumImage() throws {
        let image = createTestImage(size: CGSize(width: 512, height: 512))

        measure {
            _ = FloodFillService.floodFill(
                image: image,
                at: CGPoint(x: 256, y: 256),
                with: .blue
            )
        }
    }

    func testFloodFillPerformanceLargeImage() throws {
        let image = createTestImage(size: CGSize(width: 1024, height: 1024))

        measure {
            _ = FloodFillService.floodFill(
                image: image,
                at: CGPoint(x: 512, y: 512),
                with: .green
            )
        }
    }

    // MARK: - Progress Calculation Performance

    func testProgressCalculationPerformanceSmall() throws {
        let image = createColoredTestImage(size: CGSize(width: 256, height: 256))

        measure {
            _ = FloodFillService.calculateProgress(for: image)
        }
    }

    func testProgressCalculationPerformanceLarge() throws {
        let image = createColoredTestImage(size: CGSize(width: 1024, height: 1024))

        measure {
            _ = FloodFillService.calculateProgress(for: image)
        }
    }

    // MARK: - FillEngine Performance

    func testFillEngineMultipleFillsPerformance() throws {
        let image = createTestImage(size: CGSize(width: 512, height: 512))
        let engine = FillEngine(image: image)

        measure {
            for i in 0..<10 {
                let x = CGFloat(i) * 0.08 + 0.1
                engine.fill(at: CGPoint(x: x, y: 0.5), with: .orange)
            }
        }
    }

    func testFillEngineUndoPerformance() throws {
        let image = createTestImage(size: CGSize(width: 512, height: 512))
        let engine = FillEngine(image: image)

        // Setup: fill 10 times
        for i in 0..<10 {
            let x = CGFloat(i) * 0.08 + 0.1
            engine.fill(at: CGPoint(x: x, y: 0.5), with: .purple)
        }

        measure {
            while engine.canUndo {
                engine.undo()
            }
        }
    }

    // MARK: - DrawingEngine Performance

    func testDrawingEnginePathCreationPerformance() throws {
        let engine = DrawingEngine()

        measure {
            for i in 0..<100 {
                let x = CGFloat(i * 5)
                engine.startPath(at: CGPoint(x: x, y: 100), color: .red, lineWidth: 10, isEraser: false)
                for j in 0..<20 {
                    engine.addPoint(CGPoint(x: x + CGFloat(j), y: 100 + CGFloat(j)))
                }
                engine.endPath()
            }
        }
    }

    // MARK: - Image Rendering Performance

    func testImageRenderingPerformance() throws {
        measure {
            _ = createTestImage(size: CGSize(width: 1024, height: 1024))
        }
    }

    // MARK: - Category Loading Performance

    func testCategoryLoadingPerformance() throws {
        measure {
            let _ = Category.all
            let _ = ColoringPage.animals
            let _ = ColoringPage.vehicles
            let _ = ColoringPage.houses
            let _ = ColoringPage.nature
            let _ = ColoringPage.ocean
        }
    }

    // MARK: - Memory Tests

    func testFloodFillMemoryUsage() throws {
        let image = createTestImage(size: CGSize(width: 1024, height: 1024))

        // This is more of a smoke test - ensure no memory leaks
        for _ in 0..<5 {
            autoreleasepool {
                _ = FloodFillService.floodFill(
                    image: image,
                    at: CGPoint(x: 512, y: 512),
                    with: .cyan
                )
            }
        }
    }

    // MARK: - Helpers

    private func createTestImage(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            UIColor.black.setStroke()
            let path = UIBezierPath()
            path.lineWidth = 4

            // Create a grid of rectangles for flood fill testing
            let cellSize = size.width / 4
            for row in 0..<4 {
                for col in 0..<4 {
                    let rect = CGRect(
                        x: CGFloat(col) * cellSize + 5,
                        y: CGFloat(row) * cellSize + 5,
                        width: cellSize - 10,
                        height: cellSize - 10
                    )
                    path.append(UIBezierPath(rect: rect))
                }
            }
            path.stroke()
        }
    }

    private func createColoredTestImage(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // Half white, half colored
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: CGSize(width: size.width, height: size.height / 2)))

            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: size.height / 2, width: size.width, height: size.height / 2))
        }
    }
}
