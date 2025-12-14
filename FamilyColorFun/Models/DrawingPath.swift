import SwiftUI

struct DrawingPath: Identifiable {
    let id = UUID()
    var points: [CGPoint]
    var color: Color
    var lineWidth: CGFloat
    var isEraser: Bool

    init(points: [CGPoint] = [], color: Color = .black, lineWidth: CGFloat = 8, isEraser: Bool = false) {
        self.points = points
        self.color = color
        self.lineWidth = lineWidth
        self.isEraser = isEraser
    }
}

struct FilledArea: Identifiable {
    let id = UUID()
    let point: CGPoint
    let color: Color
}
