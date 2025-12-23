import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = SettingsManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showParentZone = false
    @State private var showPINEntry = false
    @State private var enteredPIN = ""
    @State private var pinError = false

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

                // MARK: - Parent Zone Section
                Section {
                    Button {
                        if ParentalControlsManager.shared.pinCode != nil {
                            showPINEntry = true
                        } else {
                            showParentZone = true
                        }
                        SoundManager.shared.playTap()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "lock.shield.fill")
                                .font(.title2)
                                .foregroundStyle(.purple)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Parent Zone")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("Time limits, profiles & stats")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                } header: {
                    Label("Parental Controls", systemImage: "person.badge.shield.checkmark")
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
            .sheet(isPresented: $showParentZone) {
                ParentZoneView()
            }
            .sheet(isPresented: $showPINEntry) {
                PINEntrySheet(
                    onVerify: { pin in
                        if ParentalControlsManager.shared.verifyPIN(pin) {
                            showPINEntry = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                showParentZone = true
                            }
                            return true
                        }
                        return false
                    },
                    onCancel: {
                        showPINEntry = false
                    }
                )
            }
        }
    }
}

// MARK: - PIN Entry Sheet
struct PINEntrySheet: View {
    let onVerify: (String) -> Bool
    let onCancel: () -> Void

    @State private var pin = ""
    @State private var showError = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "lock.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.purple)

                Text("Enter PIN")
                    .font(.title2)
                    .fontWeight(.semibold)

                HStack(spacing: 16) {
                    ForEach(0..<4) { index in
                        Circle()
                            .fill(pin.count > index ? Color.purple : Color.gray.opacity(0.3))
                            .frame(width: 16, height: 16)
                    }
                }

                if showError {
                    Text("Incorrect PIN")
                        .foregroundStyle(.red)
                        .font(.caption)
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                    ForEach(1...9, id: \.self) { number in
                        PINEntryButton(number: "\(number)") {
                            appendDigit("\(number)")
                        }
                    }

                    Button {
                        pin = ""
                        showError = false
                    } label: {
                        Text("Clear")
                            .font(.headline)
                            .foregroundStyle(.red)
                            .frame(width: 70, height: 70)
                    }

                    PINEntryButton(number: "0") {
                        appendDigit("0")
                    }

                    Button {
                        if !pin.isEmpty {
                            pin.removeLast()
                            showError = false
                        }
                    } label: {
                        Image(systemName: "delete.left")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                            .frame(width: 70, height: 70)
                    }
                }
                .padding(.horizontal, 40)

                Spacer()
            }
            .padding(.top, 40)
            .navigationTitle("Parent Zone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
        }
    }

    private func appendDigit(_ digit: String) {
        showError = false
        if pin.count < 4 {
            pin += digit
        }
        if pin.count == 4 {
            if !onVerify(pin) {
                showError = true
                pin = ""
            }
        }
    }
}

// MARK: - PIN Entry Button
struct PINEntryButton: View {
    let number: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(number)
                .font(.title)
                .fontWeight(.medium)
                .frame(width: 70, height: 70)
                .background(Color(.systemGray6))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    SettingsView()
}
