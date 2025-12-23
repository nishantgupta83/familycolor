import SwiftUI

// MARK: - Crayon Shape
struct CrayonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let tipHeight = rect.height * 0.18
        let bodyTop = tipHeight

        // Crayon tip (pointed triangle)
        path.move(to: CGPoint(x: rect.midX, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX - 2, y: bodyTop))
        path.addLine(to: CGPoint(x: rect.minX + 2, y: bodyTop))
        path.closeSubpath()

        // Crayon body (rounded rectangle)
        let bodyRect = CGRect(x: 2, y: bodyTop - 1,
                              width: rect.width - 4,
                              height: rect.height - bodyTop + 1)
        path.addRoundedRect(in: bodyRect, cornerSize: CGSize(width: 3, height: 3))

        return path
    }
}

// MARK: - Crayon Button
struct CrayonButton: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    var onLongPress: (() -> Void)? = nil

    @State private var isPressed = false

    private let crayonWidth: CGFloat = 26
    private let crayonHeight: CGFloat = 52

    var body: some View {
        ZStack {
            // Main crayon
            CrayonShape()
                .fill(color)
                .frame(width: crayonWidth, height: crayonHeight)

            // Highlight stripe (makes it look more 3D)
            CrayonShape()
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.3), .clear, .black.opacity(0.1)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: crayonWidth, height: crayonHeight)

            // Border
            CrayonShape()
                .stroke(isSelected ? Color.white : Color.black.opacity(0.2), lineWidth: isSelected ? 2.5 : 1)
                .frame(width: crayonWidth, height: crayonHeight)
        }
        .shadow(color: isSelected ? color.opacity(0.5) : .black.opacity(0.15), radius: isSelected ? 4 : 2, y: 2)
        .scaleEffect(isPressed ? 0.9 : (isSelected ? 1.15 : 1.0))
        .rotationEffect(.degrees(isSelected ? -5 : 0))
        .offset(y: isSelected ? -4 : 0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .onTapGesture {
            action()
        }
        .onLongPressGesture(minimumDuration: 0.4) {
            onLongPress?()
        } onPressingChanged: { pressing in
            isPressed = pressing
        }
    }
}

// MARK: - Color Palette
struct ColorPalette: View {
    @Binding var selectedColor: Color
    @ObservedObject private var settings = SettingsManager.shared
    @State private var showingShades = false
    @State private var longPressedColor: Color? = nil
    @State private var shadeColors: [Color] = []

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main crayon palette
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Array(settings.currentColors.enumerated()), id: \.offset) { index, color in
                        CrayonButton(
                            color: color,
                            isSelected: selectedColor == color
                        ) {
                            selectedColor = color
                            SoundManager.shared.playTap()
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                        } onLongPress: {
                            showShades(for: color)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6).opacity(0.8))
            )
            .padding(.horizontal, 8)

            // Shade picker overlay
            if showingShades, let _ = longPressedColor {
                ShadePickerView(
                    shades: shadeColors,
                    onSelect: { shade in
                        selectedColor = shade
                        showingShades = false
                        SoundManager.shared.playTap()
                    },
                    onDismiss: {
                        showingShades = false
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: showingShades)
    }

    private func showShades(for color: Color) {
        longPressedColor = color
        shadeColors = generateShades(for: color)
        showingShades = true

        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }

    private func generateShades(for color: Color) -> [Color] {
        let uiColor = UIColor(color)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        return [
            Color(UIColor(hue: hue, saturation: max(0, saturation - 0.3), brightness: min(1, brightness + 0.3), alpha: alpha)),
            Color(UIColor(hue: hue, saturation: max(0, saturation - 0.15), brightness: min(1, brightness + 0.15), alpha: alpha)),
            color,
            Color(UIColor(hue: hue, saturation: min(1, saturation + 0.15), brightness: max(0, brightness - 0.15), alpha: alpha)),
            Color(UIColor(hue: hue, saturation: min(1, saturation + 0.3), brightness: max(0, brightness - 0.3), alpha: alpha))
        ]
    }
}

// MARK: - Shade Picker (uses small crayons)
struct ShadePickerView: View {
    let shades: [Color]
    let onSelect: (Color) -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    onDismiss()
                }

            VStack(spacing: 12) {
                Text("Select Shade")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                HStack(spacing: 10) {
                    ForEach(Array(shades.enumerated()), id: \.offset) { index, shade in
                        Button {
                            onSelect(shade)
                        } label: {
                            ZStack {
                                CrayonShape()
                                    .fill(shade)
                                    .frame(width: 22, height: 44)
                                CrayonShape()
                                    .fill(
                                        LinearGradient(
                                            colors: [.white.opacity(0.25), .clear],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: 22, height: 44)
                                CrayonShape()
                                    .stroke(Color.black.opacity(0.15), lineWidth: 1)
                                    .frame(width: 22, height: 44)
                            }
                            .shadow(color: shade.opacity(0.3), radius: 2, y: 1)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.15), radius: 8, y: -2)
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
    }
}

// MARK: - Legacy ColorButton (for compatibility)
struct ColorButton: View {
    let color: Color
    let isSelected: Bool
    let size: CGFloat
    let action: () -> Void
    var onLongPress: (() -> Void)? = nil

    var body: some View {
        CrayonButton(color: color, isSelected: isSelected, action: action, onLongPress: onLongPress)
    }
}

#Preview {
    VStack {
        Spacer()
        ColorPalette(selectedColor: .constant(.red))
            .padding()
            .background(Color(.systemBackground))
    }
}
