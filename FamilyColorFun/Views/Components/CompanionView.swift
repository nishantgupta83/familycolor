import SwiftUI

// MARK: - Companion View

struct CompanionView: View {
    let canvasSize: CGSize

    @ObservedObject private var controller = CompanionController.shared
    @State private var currentFrame: Int = 0
    @State private var dragOffset: CGSize = .zero

    private let companionSize: CGFloat = 80

    var body: some View {
        if controller.isVisible {
            ZStack {
                // Speech bubble
                if let dialogue = controller.dialogue {
                    SpeechBubble(text: dialogue)
                        .position(
                            x: position.x,
                            y: max(60, position.y - companionSize - 30)
                        )
                        .transition(.scale.combined(with: .opacity))
                        .zIndex(1)
                }

                // Companion character
                CompanionCharacterView(
                    animationState: controller.animationState,
                    outfit: controller.currentOutfit,
                    frame: currentFrame
                )
                .frame(width: companionSize, height: companionSize)
                .position(position)
                .offset(dragOffset)
                .gesture(dragGesture)
                .onTapGesture {
                    controller.wakeUp()
                    controller.triggerEncouragement()
                }
            }
            .animation(.spring(response: 0.3), value: controller.dialogue != nil)
            .onAppear {
                startAnimation()
            }
        }
    }

    private var position: CGPoint {
        CGPoint(
            x: controller.positionX * canvasSize.width,
            y: controller.positionY * canvasSize.height
        )
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
                controller.wakeUp()
            }
            .onEnded { value in
                // Calculate new position
                let newX = (position.x + value.translation.width) / canvasSize.width
                let newY = (position.y + value.translation.height) / canvasSize.height

                // Clamp to valid range
                controller.positionX = min(max(0.1, newX), 0.9)
                controller.positionY = min(max(0.1, newY), 0.9)
                controller.savePosition()

                dragOffset = .zero
            }
    }

    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: controller.animationState.frameDuration, repeats: true) { _ in
            currentFrame = (currentFrame + 1) % controller.animationState.frameCount
        }
    }
}

// MARK: - Companion Character View

private struct CompanionCharacterView: View {
    let animationState: CompanionAnimationState
    let outfit: CompanionOutfit
    let frame: Int

    var body: some View {
        ZStack {
            // Base character
            characterImage

            // Outfit overlay
            if outfit != .none {
                outfitImage
            }
        }
        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
    }

    @ViewBuilder
    private var characterImage: some View {
        let imageName = CompanionCharacter.frameName(state: animationState, frame: frame)
        if let uiImage = UIImage(named: imageName) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            // Fallback placeholder
            PlaceholderCompanion(animationState: animationState)
        }
    }

    @ViewBuilder
    private var outfitImage: some View {
        if let uiImage = UIImage(named: outfit.imageName) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
    }
}

// MARK: - Placeholder Companion (when assets not available)

private struct PlaceholderCompanion: View {
    let animationState: CompanionAnimationState

    var body: some View {
        ZStack {
            // Body
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.orange.opacity(0.9), Color.brown.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // Face
            VStack(spacing: 4) {
                // Eyes
                HStack(spacing: 12) {
                    Eye(isClosed: animationState == .sleeping)
                    Eye(isClosed: animationState == .sleeping)
                }

                // Mouth
                Mouth(animationState: animationState)
            }
            .offset(y: 4)

            // Ears
            HStack {
                Ear()
                    .offset(x: -8, y: -28)
                Spacer()
                Ear()
                    .offset(x: 8, y: -28)
            }
            .padding(.horizontal, 8)
        }
    }
}

private struct Eye: View {
    let isClosed: Bool

    var body: some View {
        if isClosed {
            Capsule()
                .fill(Color.black)
                .frame(width: 10, height: 3)
        } else {
            Circle()
                .fill(Color.black)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 3, height: 3)
                        .offset(x: 1, y: -1)
                )
        }
    }
}

private struct Mouth: View {
    let animationState: CompanionAnimationState

    var body: some View {
        switch animationState {
        case .talking:
            Ellipse()
                .fill(Color.red.opacity(0.7))
                .frame(width: 12, height: 10)
        case .celebrating:
            // Big smile
            Capsule()
                .fill(Color.red.opacity(0.7))
                .frame(width: 16, height: 8)
        case .sleeping:
            // Small closed mouth
            Capsule()
                .fill(Color.red.opacity(0.5))
                .frame(width: 8, height: 3)
        default:
            // Normal smile
            Capsule()
                .fill(Color.red.opacity(0.6))
                .frame(width: 10, height: 5)
        }
    }
}

private struct Ear: View {
    var body: some View {
        Ellipse()
            .fill(
                LinearGradient(
                    colors: [Color.orange.opacity(0.8), Color.brown.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 14, height: 22)
    }
}

// MARK: - Speech Bubble

private struct SpeechBubble: View {
    let text: String

    var body: some View {
        VStack(spacing: 0) {
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.regularMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                )

            // Tail
            Triangle()
                .fill(.regularMaterial)
                .frame(width: 16, height: 10)
                .rotationEffect(.degrees(180))
        }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Preview

#Preview("Companion") {
    ZStack {
        Color.gray.opacity(0.3)
        CompanionView(canvasSize: CGSize(width: 400, height: 600))
    }
}
