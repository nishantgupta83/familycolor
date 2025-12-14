import SwiftUI

struct ColorPalette: View {
    @Binding var selectedColor: Color
    @ObservedObject private var settings = SettingsManager.shared
    @State private var showingShades = false
    @State private var longPressedColor: Color? = nil
    @State private var shadeColors: [Color] = []

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main color palette
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(settings.currentColors.enumerated()), id: \.offset) { index, color in
                        ColorButton(
                            color: color,
                            isSelected: selectedColor == color,
                            size: 40
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
                .padding(.vertical, 4)
            }

            // Shade picker overlay
            if showingShades, let baseColor = longPressedColor {
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

        // Generate 5 shades: 2 lighter, original, 2 darker
        return [
            Color(UIColor(hue: hue, saturation: max(0, saturation - 0.3), brightness: min(1, brightness + 0.3), alpha: alpha)),
            Color(UIColor(hue: hue, saturation: max(0, saturation - 0.15), brightness: min(1, brightness + 0.15), alpha: alpha)),
            color, // Original
            Color(UIColor(hue: hue, saturation: min(1, saturation + 0.15), brightness: max(0, brightness - 0.15), alpha: alpha)),
            Color(UIColor(hue: hue, saturation: min(1, saturation + 0.3), brightness: max(0, brightness - 0.3), alpha: alpha))
        ]
    }
}

struct ColorButton: View {
    let color: Color
    let isSelected: Bool
    let size: CGFloat
    let action: () -> Void
    var onLongPress: (() -> Void)? = nil

    @State private var isPressed = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: isSelected ? 3 : 0)
            )
            .overlay(
                Circle()
                    .stroke(Color.black.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: isSelected ? color.opacity(0.4) : .clear, radius: 4)
            .scaleEffect(isPressed ? 0.9 : (isSelected ? 1.1 : 1.0))
            .animation(.spring(response: 0.2), value: isPressed)
            .animation(.spring(response: 0.3), value: isSelected)
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

struct ShadePickerView: View {
    let shades: [Color]
    let onSelect: (Color) -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Dismiss area
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    onDismiss()
                }

            // Shade picker
            VStack(spacing: 12) {
                Text("Select Shade")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    ForEach(Array(shades.enumerated()), id: \.offset) { index, shade in
                        Button {
                            onSelect(shade)
                        } label: {
                            Circle()
                                .fill(shade)
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Circle()
                                        .stroke(Color.black.opacity(0.1), lineWidth: 1)
                                )
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

#Preview {
    VStack {
        Spacer()
        ColorPalette(selectedColor: .constant(.kidColors[0]))
            .padding()
            .background(Color(.systemBackground))
    }
}
