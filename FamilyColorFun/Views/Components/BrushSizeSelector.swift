import SwiftUI

// MARK: - Brush Size (for Phase 2 PencilKit)
enum BrushSize: CGFloat, CaseIterable {
    case small = 6
    case medium = 14
    case large = 24
}

enum DrawingTool {
    case brush, eraser, fill
}

struct BrushSizeSelector: View {
    @Binding var selectedSize: BrushSize
    @Binding var currentTool: DrawingTool

    var body: some View {
        HStack(spacing: 8) {
            ForEach(BrushSize.allCases, id: \.rawValue) { size in
                Button {
                    selectedSize = size
                    currentTool = .brush
                    SoundManager.shared.playTap()
                } label: {
                    Circle()
                        .fill(selectedSize == size && currentTool == .brush ? Color.pink : Color(.systemGray4))
                        .frame(width: circleSize(for: size), height: circleSize(for: size))
                        .frame(width: 44, height: 44)
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }

    private func circleSize(for size: BrushSize) -> CGFloat {
        switch size {
        case .small: return 12
        case .medium: return 20
        case .large: return 28
        }
    }
}

#Preview {
    BrushSizeSelector(
        selectedSize: .constant(.medium),
        currentTool: .constant(.brush)
    )
}
