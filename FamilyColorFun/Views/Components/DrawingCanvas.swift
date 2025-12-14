import SwiftUI

// MARK: - Drawing Canvas (for Phase 2 PencilKit free-draw mode)
struct DrawingCanvas: View {
    @ObservedObject var engine: DrawingEngine
    let currentColor: Color
    let brushSize: CGFloat
    let currentTool: DrawingTool

    var body: some View {
        Canvas { context, size in
            // Draw filled areas
            for filled in engine.filledAreas {
                let rect = CGRect(
                    x: filled.point.x - 30,
                    y: filled.point.y - 30,
                    width: 60,
                    height: 60
                )
                context.fill(
                    Circle().path(in: rect),
                    with: .color(filled.color)
                )
            }

            // Draw completed paths
            for path in engine.paths {
                drawPath(path, in: &context)
            }

            // Draw current path
            if let currentPath = engine.currentPath {
                drawPath(currentPath, in: &context)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    handleDrag(value)
                }
                .onEnded { _ in
                    handleDragEnd()
                }
        )
        .onTapGesture { location in
            handleTap(at: location)
        }
    }

    private func drawPath(_ path: DrawingPath, in context: inout GraphicsContext) {
        guard path.points.count > 1 else { return }

        var bezierPath = Path()
        bezierPath.move(to: path.points[0])

        for i in 1..<path.points.count {
            let point = path.points[i]
            let previousPoint = path.points[i - 1]

            let midPoint = CGPoint(
                x: (previousPoint.x + point.x) / 2,
                y: (previousPoint.y + point.y) / 2
            )

            bezierPath.addQuadCurve(to: midPoint, control: previousPoint)
        }

        if let lastPoint = path.points.last {
            bezierPath.addLine(to: lastPoint)
        }

        if path.isEraser {
            context.blendMode = .destinationOut
            context.stroke(
                bezierPath,
                with: .color(.white),
                style: StrokeStyle(lineWidth: path.lineWidth, lineCap: .round, lineJoin: .round)
            )
            context.blendMode = .normal
        } else {
            context.stroke(
                bezierPath,
                with: .color(path.color),
                style: StrokeStyle(lineWidth: path.lineWidth, lineCap: .round, lineJoin: .round)
            )
        }
    }

    private func handleDrag(_ value: DragGesture.Value) {
        let point = value.location

        switch currentTool {
        case .brush:
            if engine.currentPath == nil {
                engine.startPath(at: point, color: currentColor, lineWidth: brushSize, isEraser: false)
                SoundManager.shared.playTap()
            } else {
                engine.addPoint(point)
            }

        case .eraser:
            if engine.currentPath == nil {
                engine.startPath(at: point, color: .white, lineWidth: brushSize * 2, isEraser: true)
            } else {
                engine.addPoint(point)
            }

        case .fill:
            break
        }
    }

    private func handleDragEnd() {
        engine.endPath()
    }

    private func handleTap(at location: CGPoint) {
        if currentTool == .fill {
            engine.fill(at: location, with: currentColor)
        }
    }
}
