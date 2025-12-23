import SwiftUI

struct ParentZoneView: View {
    @ObservedObject private var parentalControls = ParentalControlsManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var showAddProfile = false
    @State private var showPINSetup = false
    @State private var newProfileName = ""
    @State private var selectedAvatar = "face.smiling"

    var body: some View {
        NavigationStack {
            List {
                // Time Limits Section
                timeLimitsSection

                // Child Profiles Section
                childProfilesSection

                // Usage Statistics Section
                usageStatisticsSection

                // PIN Protection Section
                pinProtectionSection
            }
            .navigationTitle("Parent Zone")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showAddProfile) {
                addProfileSheet
            }
            .sheet(isPresented: $showPINSetup) {
                PINSetupView()
            }
        }
    }

    // MARK: - Time Limits Section
    private var timeLimitsSection: some View {
        Section {
            Toggle(isOn: $parentalControls.timeLimitEnabled) {
                Label("Daily Time Limit", systemImage: "clock.fill")
            }
            .tint(.orange)

            if parentalControls.timeLimitEnabled {
                HStack {
                    Text("Limit")
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button {
                        parentalControls.adjustTimeLimit(by: -5)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.orange)
                    }
                    .buttonStyle(.plain)

                    Text("\(parentalControls.dailyTimeLimitMinutes) min")
                        .font(.headline)
                        .monospacedDigit()
                        .frame(width: 70)

                    Button {
                        parentalControls.adjustTimeLimit(by: 5)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.orange)
                    }
                    .buttonStyle(.plain)
                }

                // Today's usage
                HStack {
                    Text("Used Today")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(parentalControls.timeUsedTodayMinutes) min")
                        .font(.headline)
                        .foregroundStyle(parentalControls.isTimeLimitReached ? .red : .green)
                }

                // Progress bar
                ProgressView(value: Double(parentalControls.timeUsedTodayMinutes),
                             total: Double(parentalControls.dailyTimeLimitMinutes))
                    .tint(parentalControls.isTimeLimitReached ? .red : .green)
            }
        } header: {
            Text("Time Limits")
        } footer: {
            if parentalControls.timeLimitEnabled {
                Text("Coloring will pause when the daily limit is reached.")
            }
        }
    }

    // MARK: - Child Profiles Section
    private var childProfilesSection: some View {
        Section {
            ForEach(parentalControls.profiles) { profile in
                HStack(spacing: 12) {
                    Image(systemName: profile.avatarName)
                        .font(.title2)
                        .foregroundStyle(.purple)
                        .frame(width: 40, height: 40)
                        .background(Color.purple.opacity(0.1))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(profile.name)
                            .font(.headline)
                        Text("\(profile.progress.totalStarsEarned) stars earned")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if parentalControls.activeProfileId == profile.id {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    parentalControls.switchProfile(to: profile.id)
                }
            }
            .onDelete { indexSet in
                indexSet.forEach { index in
                    parentalControls.deleteProfile(parentalControls.profiles[index])
                }
            }

            Button {
                showAddProfile = true
            } label: {
                Label("Add Child Profile", systemImage: "plus.circle.fill")
            }
        } header: {
            Text("Child Profiles")
        } footer: {
            Text("Each child can track their own progress and rewards.")
        }
    }

    // MARK: - Usage Statistics Section
    private var usageStatisticsSection: some View {
        Section {
            // Today
            StatRow(
                icon: "clock",
                title: "Time Colored Today",
                value: "\(parentalControls.todayUsage.minutesColored) min",
                color: .blue
            )

            StatRow(
                icon: "doc.richtext",
                title: "Pages Today",
                value: "\(parentalControls.todayUsage.pagesCompleted)",
                color: .green
            )

            StatRow(
                icon: "star.fill",
                title: "Stars Today",
                value: "\(parentalControls.todayUsage.starsEarned)",
                color: .yellow
            )

            Divider()

            // This Week
            StatRow(
                icon: "calendar",
                title: "This Week",
                value: formatTime(parentalControls.weeklySummary.totalMinutes),
                color: .purple
            )

            StatRow(
                icon: "chart.bar.fill",
                title: "Daily Average",
                value: "\(parentalControls.weeklySummary.averageMinutesPerDay) min",
                color: .orange
            )
        } header: {
            Text("Usage Statistics")
        }
    }

    // MARK: - PIN Protection Section
    private var pinProtectionSection: some View {
        Section {
            Button {
                showPINSetup = true
            } label: {
                HStack {
                    Label(
                        parentalControls.pinCode != nil ? "Change PIN" : "Set PIN",
                        systemImage: "lock.fill"
                    )
                    Spacer()
                    if parentalControls.pinCode != nil {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
            }
        } header: {
            Text("Security")
        } footer: {
            Text("Protect Parent Zone with a 4-digit PIN.")
        }
    }

    // MARK: - Add Profile Sheet
    private var addProfileSheet: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Child's Name", text: $newProfileName)
                }

                Section("Avatar") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 12) {
                        ForEach(ChildProfile.avatarOptions, id: \.self) { avatar in
                            Button {
                                selectedAvatar = avatar
                            } label: {
                                Image(systemName: avatar)
                                    .font(.title)
                                    .foregroundStyle(selectedAvatar == avatar ? .white : .purple)
                                    .frame(width: 50, height: 50)
                                    .background(
                                        Circle()
                                            .fill(selectedAvatar == avatar ? Color.purple : Color.purple.opacity(0.1))
                                    )
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Add Child")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showAddProfile = false
                        newProfileName = ""
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        parentalControls.addProfile(name: newProfileName, avatar: selectedAvatar)
                        showAddProfile = false
                        newProfileName = ""
                    }
                    .disabled(newProfileName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func formatTime(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins) min"
    }
}

// MARK: - Stat Row
struct StatRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)

            Text(title)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.headline)
                .monospacedDigit()
        }
    }
}

// MARK: - PIN Setup View
struct PINSetupView: View {
    @ObservedObject private var parentalControls = ParentalControlsManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var pin = ""
    @State private var confirmPIN = ""
    @State private var step = 1
    @State private var showError = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "lock.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.purple)

                Text(step == 1 ? "Enter a 4-digit PIN" : "Confirm your PIN")
                    .font(.title2)
                    .fontWeight(.semibold)

                // PIN dots
                HStack(spacing: 16) {
                    ForEach(0..<4) { index in
                        Circle()
                            .fill(currentPIN.count > index ? Color.purple : Color.gray.opacity(0.3))
                            .frame(width: 16, height: 16)
                    }
                }

                if showError {
                    Text("PINs don't match. Try again.")
                        .foregroundStyle(.red)
                        .font(.caption)
                }

                // Number pad
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                    ForEach(1...9, id: \.self) { number in
                        PINButton(number: "\(number)") {
                            appendDigit("\(number)")
                        }
                    }

                    Button {
                        // Clear
                        if step == 1 {
                            pin = ""
                        } else {
                            confirmPIN = ""
                        }
                    } label: {
                        Text("Clear")
                            .font(.headline)
                            .foregroundStyle(.red)
                            .frame(width: 70, height: 70)
                    }

                    PINButton(number: "0") {
                        appendDigit("0")
                    }

                    Button {
                        // Delete
                        if step == 1 && !pin.isEmpty {
                            pin.removeLast()
                        } else if step == 2 && !confirmPIN.isEmpty {
                            confirmPIN.removeLast()
                        }
                    } label: {
                        Image(systemName: "delete.left")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                            .frame(width: 70, height: 70)
                    }
                }
                .padding(.horizontal, 40)

                if parentalControls.pinCode != nil {
                    Button("Remove PIN") {
                        parentalControls.setPIN("")
                        dismiss()
                    }
                    .foregroundStyle(.red)
                }

                Spacer()
            }
            .padding(.top, 40)
            .navigationTitle("Set PIN")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var currentPIN: String {
        step == 1 ? pin : confirmPIN
    }

    private func appendDigit(_ digit: String) {
        showError = false

        if step == 1 {
            if pin.count < 4 {
                pin += digit
            }
            if pin.count == 4 {
                step = 2
            }
        } else {
            if confirmPIN.count < 4 {
                confirmPIN += digit
            }
            if confirmPIN.count == 4 {
                if pin == confirmPIN {
                    parentalControls.setPIN(pin)
                    dismiss()
                } else {
                    showError = true
                    confirmPIN = ""
                }
            }
        }
    }
}

// MARK: - PIN Button
struct PINButton: View {
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

// MARK: - Time Limit Alert View
struct TimeLimitAlertView: View {
    @Binding var isPresented: Bool
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundStyle(.orange)

            Text("Time's Up!")
                .font(.title)
                .fontWeight(.bold)

            Text("You've reached your daily coloring limit. Come back tomorrow for more fun!")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            Button {
                isPresented = false
                onDismiss()
            } label: {
                Text("OK")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 40)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemBackground))
        )
        .shadow(radius: 20)
        .padding(40)
    }
}

#Preview {
    ParentZoneView()
}
