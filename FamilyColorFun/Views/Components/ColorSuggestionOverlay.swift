import SwiftUI

// MARK: - Color Suggestion Overlay

struct ColorSuggestionOverlay: View {
    let suggestions: [ColorSuggestion]
    let imageSize: CGSize
    let displaySize: CGSize
    let onTapSuggestion: (ColorSuggestion) -> Void
    let onDismiss: () -> Void

    @State private var isPulsing = false
    @State private var showSparkles = true

    var body: some View {
        ZStack {
            // Semi-transparent backdrop (subtle, allows seeing artwork)
            Color.black.opacity(0.05)
                .onTapGesture {
                    onDismiss()
                }

            // Suggestion highlights
            ForEach(suggestions) { suggestion in
                SuggestionHighlight(
                    suggestion: suggestion,
                    imageSize: imageSize,
                    displaySize: displaySize,
                    isPulsing: isPulsing,
                    onTap: {
                        onTapSuggestion(suggestion)
                    }
                )
            }

            // Dismiss button (top-right corner)
            VStack {
                HStack {
                    Spacer()
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white, .black.opacity(0.5))
                            .shadow(color: .black.opacity(0.3), radius: 2)
                    }
                    .padding()
                }
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}

// MARK: - Suggestion Highlight

struct SuggestionHighlight: View {
    let suggestion: ColorSuggestion
    let imageSize: CGSize
    let displaySize: CGSize
    let isPulsing: Bool
    let onTap: () -> Void

    @State private var sparkleRotation: Double = 0
    @State private var bounceScale: CGFloat = 1.0

    private var scaledPosition: CGPoint {
        let scaleX = displaySize.width / imageSize.width
        let scaleY = displaySize.height / imageSize.height
        return CGPoint(
            x: suggestion.centroid.x * scaleX,
            y: suggestion.centroid.y * scaleY
        )
    }

    var body: some View {
        ZStack {
            // Outer glow ring
            Circle()
                .stroke(suggestion.suggestedColor.opacity(0.6), lineWidth: isPulsing ? 6 : 3)
                .frame(width: 70, height: 70)
                .scaleEffect(isPulsing ? 1.2 : 1.0)

            // Inner color preview circle
            Circle()
                .fill(suggestion.suggestedColor)
                .frame(width: 50, height: 50)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                )
                .shadow(color: suggestion.suggestedColor.opacity(0.5), radius: isPulsing ? 12 : 6)

            // Sparkle decorations
            ForEach(0..<4, id: \.self) { index in
                Image(systemName: "sparkle")
                    .font(.system(size: 14))
                    .foregroundStyle(.yellow)
                    .offset(x: 35, y: 0)
                    .rotationEffect(.degrees(Double(index) * 90 + sparkleRotation))
                    .opacity(isPulsing ? 1 : 0.5)
            }

            // "Tap!" hint text
            Text("Tap!")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.6))
                )
                .offset(y: 45)
        }
        .scaleEffect(bounceScale)
        .position(scaledPosition)
        .onTapGesture {
            // Bounce animation on tap
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                bounceScale = 1.3
            }

            // Play tap sound and haptic
            SoundManager.shared.playTap()
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()

            // Slight delay before action for visual feedback
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                onTap()
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                sparkleRotation = 360
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gray.opacity(0.2)

        ColorSuggestionOverlay(
            suggestions: [
                ColorSuggestion(
                    regionId: 1,
                    suggestedColor: .orange,
                    paletteIndex: 1,
                    centroid: CGPoint(x: 150, y: 200),
                    boundingBox: CGRect(x: 100, y: 150, width: 100, height: 100)
                ),
                ColorSuggestion(
                    regionId: 2,
                    suggestedColor: .brown,
                    paletteIndex: 10,
                    centroid: CGPoint(x: 250, y: 300),
                    boundingBox: CGRect(x: 200, y: 250, width: 100, height: 100)
                )
            ],
            imageSize: CGSize(width: 400, height: 600),
            displaySize: CGSize(width: 400, height: 600),
            onTapSuggestion: { _ in },
            onDismiss: { }
        )
    }
    .frame(width: 400, height: 600)
}
