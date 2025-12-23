import SwiftUI

/// Sliders for adjusting line art settings
struct AdjustmentSliders: View {
    @Binding var thickness: Double
    @Binding var detail: Double
    @Binding var selectedPreset: LineArtPreset?

    var body: some View {
        VStack(spacing: 16) {
            // Presets
            presetPicker

            Divider()

            // Manual adjustments
            thicknessSlider
            detailSlider
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }

    private var presetPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Presets")
                .font(.subheadline)
                .foregroundColor(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(LineArtPreset.allCases, id: \.self) { preset in
                        PresetButton(
                            preset: preset,
                            isSelected: selectedPreset == preset
                        ) {
                            selectedPreset = preset
                            applyPreset(preset)
                        }
                    }
                }
            }
        }
    }

    private var thicknessSlider: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Line Thickness")
                    .font(.subheadline)
                Spacer()
                Text(thicknessLabel)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Slider(value: $thickness, in: 1...5, step: 1) {
                Text("Thickness")
            }
            .onChange(of: thickness) { _ in
                selectedPreset = nil  // Clear preset when manually adjusting
            }
        }
    }

    private var detailSlider: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Detail Level")
                    .font(.subheadline)
                Spacer()
                Text(detailLabel)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Slider(value: $detail, in: 0...1) {
                Text("Detail")
            }
            .onChange(of: detail) { _ in
                selectedPreset = nil
            }
        }
    }

    private var thicknessLabel: String {
        switch Int(thickness) {
        case 1: return "Thin"
        case 2: return "Light"
        case 3: return "Medium"
        case 4: return "Bold"
        case 5: return "Heavy"
        default: return "Medium"
        }
    }

    private var detailLabel: String {
        if detail < 0.33 { return "Simple" }
        if detail < 0.66 { return "Medium" }
        return "Detailed"
    }

    private func applyPreset(_ preset: LineArtPreset) {
        let settings = preset.settings
        thickness = Double(settings.thickness)
        // Map maxDimension to 0-1 scale: 384=0, 1024=1
        detail = Double(settings.maxDimension - 384) / 640.0
    }
}

struct PresetButton: View {
    let preset: LineArtPreset
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: preset.icon)
                    .font(.title2)
                Text(preset.displayName)
                    .font(.caption)
            }
            .frame(width: 70, height: 60)
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color(.systemGray6))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
