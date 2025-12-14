import SwiftUI

class DrawingEngine: ObservableObject {
    @Published var paths: [DrawingPath] = []
    @Published var filledAreas: [FilledArea] = []
    @Published var currentPath: DrawingPath?
    @Published var progress: Double = 0.0

    private var undoStack: [[DrawingPath]] = []
    private let maxUndoSteps = 10

    var canUndo: Bool {
        !paths.isEmpty || !filledAreas.isEmpty
    }

    // MARK: - Drawing

    func startPath(at point: CGPoint, color: Color, lineWidth: CGFloat, isEraser: Bool) {
        saveForUndo()
        currentPath = DrawingPath(points: [point], color: color, lineWidth: lineWidth, isEraser: isEraser)
    }

    func addPoint(_ point: CGPoint) {
        currentPath?.points.append(point)
    }

    func endPath() {
        if let path = currentPath, path.points.count > 1 {
            paths.append(path)
            updateProgress()
        }
        currentPath = nil
    }

    // MARK: - Fill

    func fill(at point: CGPoint, with color: Color) {
        saveForUndo()
        filledAreas.append(FilledArea(point: point, color: color))
        updateProgress()
        SoundManager.shared.playFill()
    }

    // MARK: - Undo

    func undo() {
        if !paths.isEmpty {
            paths.removeLast()
            updateProgress()
        } else if !filledAreas.isEmpty {
            filledAreas.removeLast()
            updateProgress()
        }
    }

    private func saveForUndo() {
        undoStack.append(paths)
        if undoStack.count > maxUndoSteps {
            undoStack.removeFirst()
        }
    }

    // MARK: - Progress

    private func updateProgress() {
        // Simple progress calculation based on drawing activity
        let pathProgress = min(Double(paths.count) / 20.0, 0.5)
        let fillProgress = min(Double(filledAreas.count) / 10.0, 0.5)
        progress = pathProgress + fillProgress
    }

    // MARK: - Clear

    func clear() {
        saveForUndo()
        paths.removeAll()
        filledAreas.removeAll()
        progress = 0
    }
}
