import SwiftUI
import PencilKit

// MARK: - PencilKit Canvas (Phase 2)
struct PencilKitCanvas: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    @Binding var toolColor: Color
    @Binding var toolWidth: CGFloat
    @Binding var currentTool: PencilTool

    let backgroundImage: UIImage?
    var onDrawingChanged: ((PKDrawing) -> Void)?

    enum PencilTool {
        case pen
        case pencil
        case marker
        case eraser
    }

    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        canvasView.delegate = context.coordinator
        canvasView.drawingPolicy = .anyInput // Finger + Pencil
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.drawing = drawing

        // Add background image if provided
        if let bgImage = backgroundImage {
            let imageView = UIImageView(image: bgImage)
            imageView.contentMode = .scaleAspectFit
            imageView.frame = canvasView.bounds
            imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            canvasView.insertSubview(imageView, at: 0)
        }

        updateTool(canvasView)
        return canvasView
    }

    func updateUIView(_ canvasView: PKCanvasView, context: Context) {
        if canvasView.drawing != drawing {
            canvasView.drawing = drawing
        }
        updateTool(canvasView)
    }

    private func updateTool(_ canvasView: PKCanvasView) {
        let uiColor = UIColor(toolColor)

        switch currentTool {
        case .pen:
            canvasView.tool = PKInkingTool(.pen, color: uiColor, width: toolWidth)
        case .pencil:
            canvasView.tool = PKInkingTool(.pencil, color: uiColor, width: toolWidth)
        case .marker:
            canvasView.tool = PKInkingTool(.marker, color: uiColor, width: toolWidth * 2)
        case .eraser:
            if #available(iOS 16.4, *) {
                canvasView.tool = PKEraserTool(.bitmap, width: toolWidth * 3)
            } else {
                canvasView.tool = PKEraserTool(.bitmap)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: PencilKitCanvas

        init(_ parent: PencilKitCanvas) {
            self.parent = parent
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.drawing = canvasView.drawing
            parent.onDrawingChanged?(canvasView.drawing)
        }
    }
}

// MARK: - Combined Canvas View (Fill + Draw modes)
struct CombinedCanvasView: View {
    let pageImage: UIImage
    @Binding var selectedColor: Color
    @ObservedObject var fillEngine: FillEngine
    @Binding var mode: ColoringMode

    @State private var drawing = PKDrawing()
    @State private var pencilTool: PencilKitCanvas.PencilTool = .pen
    @State private var toolWidth: CGFloat = 10

    enum ColoringMode: String, CaseIterable {
        case fill = "Fill"
        case draw = "Draw"
    }

    var body: some View {
        ZStack {
            // Fill mode canvas (always visible as base)
            TapFillCanvas(
                pageImage: fillEngine.currentImage,
                selectedColor: $selectedColor,
                fillEngine: fillEngine
            )
            .allowsHitTesting(mode == .fill)

            // Draw mode overlay
            if mode == .draw {
                PencilKitCanvas(
                    drawing: $drawing,
                    toolColor: $selectedColor,
                    toolWidth: $toolWidth,
                    currentTool: $pencilTool,
                    backgroundImage: nil
                )
            }
        }
    }

    func clearDrawing() {
        drawing = PKDrawing()
    }

    func getDrawingImage() -> UIImage? {
        return drawing.image(from: drawing.bounds, scale: UIScreen.main.scale)
    }
}

// MARK: - Drawing Tools Toolbar
struct DrawingToolsBar: View {
    @Binding var selectedTool: PencilKitCanvas.PencilTool
    @Binding var brushWidth: CGFloat
    let accentColor: Color

    var body: some View {
        HStack(spacing: 16) {
            // Tool buttons
            ForEach([
                (PencilKitCanvas.PencilTool.pen, "pencil.tip"),
                (.pencil, "pencil"),
                (.marker, "highlighter"),
                (.eraser, "eraser")
            ], id: \.1) { tool, icon in
                Button {
                    selectedTool = tool
                    SoundManager.shared.playTap()
                } label: {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(selectedTool == tool ? .white : .primary)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(selectedTool == tool ? accentColor : Color(.systemGray5))
                        )
                }
            }

            Divider()
                .frame(height: 30)

            // Brush size
            HStack(spacing: 8) {
                Image(systemName: "circle.fill")
                    .font(.caption2)
                Slider(value: $brushWidth, in: 2...30)
                    .frame(width: 80)
                Image(systemName: "circle.fill")
                    .font(.title3)
            }
            .foregroundStyle(accentColor)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}

// MARK: - Preview
#Preview {
    CombinedCanvasView(
        pageImage: UIImage(),
        selectedColor: .constant(.red),
        fillEngine: FillEngine(image: UIImage()),
        mode: .constant(.draw)
    )
}
