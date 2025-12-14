import SwiftUI

struct ProgressHintOverlay: View {
    let progress: Double
    @State private var isPulsing = false

    var body: some View {
        GeometryReader { geometry in
            // Show hint when progress is between 50-99%
            if progress >= 0.5 && progress < 1.0 {
                ZStack {
                    // Sparkle particles around edges
                    ForEach(0..<5, id: \.self) { index in
                        SparkleParticle(
                            offset: CGSize(
                                width: CGFloat.random(in: -geometry.size.width/2...geometry.size.width/2),
                                height: CGFloat.random(in: -geometry.size.height/2...geometry.size.height/2)
                            )
                        )
                    }

                    // Pulsing border hint
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            LinearGradient(
                                colors: [.yellow, .orange, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: isPulsing ? 4 : 2
                        )
                        .opacity(isPulsing ? 0.8 : 0.3)
                        .animation(
                            .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                            value: isPulsing
                        )
                }
                .allowsHitTesting(false)
                .onAppear {
                    isPulsing = true
                }
            }

            // Celebration overlay when complete
            if progress >= 1.0 {
                ConfettiView()
                    .allowsHitTesting(false)
            }
        }
    }
}

struct SparkleParticle: View {
    let offset: CGSize
    @State private var isVisible = false
    @State private var scale: CGFloat = 0.5

    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: 16))
            .foregroundStyle(.yellow)
            .scaleEffect(scale)
            .opacity(isVisible ? 1 : 0)
            .offset(offset)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: Double.random(in: 0.8...1.5))
                    .repeatForever(autoreverses: true)
                    .delay(Double.random(in: 0...0.5))
                ) {
                    isVisible = true
                    scale = CGFloat.random(in: 0.8...1.2)
                }
            }
    }
}

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
                animateParticles(in: geometry.size)
            }
        }
    }

    private func createParticles(in size: CGSize) {
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]

        particles = (0..<30).map { _ in
            ConfettiParticle(
                position: CGPoint(x: size.width / 2, y: -20),
                color: colors.randomElement() ?? .red,
                size: CGFloat.random(in: 8...16),
                opacity: 1.0
            )
        }
    }

    private func animateParticles(in size: CGSize) {
        for i in particles.indices {
            let delay = Double(i) * 0.05
            let duration = Double.random(in: 1.5...2.5)

            withAnimation(.easeOut(duration: duration).delay(delay)) {
                particles[i].position = CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: size.height + 50
                )
                particles[i].opacity = 0
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    let color: Color
    let size: CGFloat
    var opacity: Double
}

#Preview {
    ZStack {
        Color.white
        ProgressHintOverlay(progress: 0.7)
    }
}
