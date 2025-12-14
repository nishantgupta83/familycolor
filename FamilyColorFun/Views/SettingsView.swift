import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = SettingsManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Color Palette Section
                Section {
                    ForEach(SettingsManager.ColorPaletteType.allCases) { palette in
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                settings.colorPalette = palette
                            }
                            SoundManager.shared.playTap()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: palette.icon)
                                    .font(.title2)
                                    .foregroundStyle(palette.colors[0])
                                    .frame(width: 32)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(palette.rawValue)
                                        .font(.headline)
                                        .foregroundStyle(.primary)

                                    // Color preview
                                    HStack(spacing: 3) {
                                        ForEach(0..<6, id: \.self) { i in
                                            Circle()
                                                .fill(palette.colors[i])
                                                .frame(width: 16, height: 16)
                                        }
                                        Text("...")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Spacer()

                                if settings.colorPalette == palette {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(.green)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Label("Color Palette", systemImage: "paintpalette")
                } footer: {
                    Text("Choose colors that match your style")
                }

                // MARK: - Age Mode Section
                Section {
                    ForEach(SettingsManager.AgeMode.allCases) { mode in
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                settings.ageMode = mode
                            }
                            SoundManager.shared.playTap()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: mode.icon)
                                    .font(.title2)
                                    .foregroundStyle(.blue)
                                    .frame(width: 32)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(mode.rawValue)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text(mode.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if settings.ageMode == mode {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(.green)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Label("Age Mode", systemImage: "person.2")
                } footer: {
                    Text("Adjusts image complexity")
                }

                // MARK: - Sound & Feedback Section
                Section {
                    Toggle(isOn: $settings.soundEnabled) {
                        Label("Sound Effects", systemImage: "speaker.wave.2")
                    }
                    .tint(.blue)

                    Toggle(isOn: $settings.hapticEnabled) {
                        Label("Haptic Feedback", systemImage: "hand.tap")
                    }
                    .tint(.blue)

                    Toggle(isOn: $settings.showHints) {
                        Label("Show Hints", systemImage: "lightbulb")
                    }
                    .tint(.blue)
                } header: {
                    Label("Feedback", systemImage: "bell")
                }

                // MARK: - About Section
                Section {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        settings.resetToDefaults()
                        SoundManager.shared.playTap()
                    } label: {
                        Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                            .foregroundStyle(.red)
                    }
                } header: {
                    Label("About", systemImage: "questionmark.circle")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    SettingsView()
}
