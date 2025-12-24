import SwiftUI
import PhotosUI

/// View for uploading and converting photos to coloring pages
struct PhotoUploadView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItem: PhotosPickerItem?
    @State private var originalPhoto: UIImage?
    @State private var lineArtPreview: UIImage?
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""

    // Settings - Default to toddler mode for young children
    @State private var thickness: Double = 6
    @State private var detail: Double = 0.2
    @State private var selectedPreset: LineArtPreset? = .toddler
    @State private var pageName: String = ""
    @State private var isToddlerMode = true  // Toggle for toddler-friendly output
    @State private var selectedEngine: EngineType = .vision

    // Processing components
    private let legacyEngine = VisionContoursEngine()
    @StateObject private var orchestrator = LineArtOrchestrator()
    private let registry = EngineRegistry.shared
    private let photoAnalyzer = PhotoAnalysisEngine()

    var onComplete: ((UserGeneratedPage) -> Void)?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let photo = originalPhoto {
                        photoPreviewSection(photo)
                    } else {
                        photoPickerSection
                    }
                }
                .padding()
            }
            .navigationTitle("Create Coloring Page")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Photo Picker

    private var photoPickerSection: some View {
        VStack(spacing: 20) {
            PhotosPicker(selection: $selectedItem, matching: .images) {
                VStack(spacing: 16) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 60))
                        .foregroundColor(.accentColor)

                    Text("Select a Photo")
                        .font(.headline)

                    Text("Choose a photo to turn into a coloring page")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .background(Color(.systemGray6))
                .cornerRadius(16)
            }
            .onChange(of: selectedItem) { newItem in
                Task { await loadPhoto(from: newItem) }
            }

            // Tips section
            tipsSection
        }
    }

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Best Photos for Coloring")
                .font(.headline)
                .foregroundColor(.primary)

            HStack(alignment: .top, spacing: 16) {
                tipCard(
                    icon: "person.crop.circle.fill",
                    title: "Portraits",
                    description: "Selfies and face photos work great!",
                    isRecommended: true
                )
                tipCard(
                    icon: "pawprint.fill",
                    title: "Pets",
                    description: "Close-up photos of pets",
                    isRecommended: true
                )
            }

            HStack(alignment: .top, spacing: 16) {
                tipCard(
                    icon: "cup.and.saucer.fill",
                    title: "Objects",
                    description: "Simple objects on plain backgrounds",
                    isRecommended: false
                )
                tipCard(
                    icon: "mountain.2.fill",
                    title: "Landscapes",
                    description: "Scenic views with clear edges",
                    isRecommended: false
                )
            }

            // Pro tip
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Pro Tip: Photos with clear outlines and good contrast make the best coloring pages!")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private func tipCard(icon: String, title: String, description: String, isRecommended: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isRecommended ? .green : .blue)
                if isRecommended {
                    Text("Best")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green)
                        .cornerRadius(4)
                }
            }
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Photo Preview

    private func photoPreviewSection(_ photo: UIImage) -> some View {
        VStack(spacing: 20) {
            // Toddler mode toggle - prominent at top
            toddlerModeToggle

            // Engine selector (only show if not in toddler mode)
            if !isToddlerMode {
                engineSelector
            }

            // Before/After comparison
            HStack(spacing: 12) {
                imagePreview(photo, label: "Original")
                imagePreview(lineArtPreview ?? photo, label: "Preview")
            }

            // Adjustment sliders (only show if not in toddler mode)
            if !isToddlerMode {
                AdjustmentSliders(
                    thickness: $thickness,
                    detail: $detail,
                    selectedPreset: $selectedPreset
                )
                .onChange(of: thickness) { _ in updatePreview() }
                .onChange(of: detail) { _ in updatePreview() }
                .onChange(of: selectedPreset) { preset in
                    if preset != nil { updatePreview() }
                }
            }

            // Page name input
            nameInput

            // Action buttons
            actionButtons
        }
    }

    // MARK: - Engine Selector

    private var engineSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "cpu")
                    .foregroundColor(.blue)
                Text("Processing Engine")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
            }

            HStack(spacing: 12) {
                engineButton(
                    engine: .vision,
                    icon: "eye.fill",
                    name: "Vision",
                    description: "Fast, reliable contours"
                )

                engineButton(
                    engine: .hed,
                    icon: "brain",
                    name: "HED",
                    description: "Deep learning edges"
                )
            }

            // Show availability info
            if !registry.isAvailable(.hed) {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.orange)
                    Text("HED model not installed. Using Vision as fallback.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func engineButton(engine: EngineType, icon: String, name: String, description: String) -> some View {
        let isSelected = selectedEngine == engine
        let isAvailable = registry.isAvailable(engine)

        return Button {
            if isAvailable {
                selectedEngine = engine
                updatePreview()
            }
        } label: {
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.title3)
                    Text(name)
                        .fontWeight(.medium)
                }

                Text(description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                if !isAvailable {
                    Text("Not Available")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.blue.opacity(0.15) : Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .opacity(isAvailable ? 1.0 : 0.5)
    }

    private var toddlerModeToggle: some View {
        VStack(spacing: 12) {
            Toggle(isOn: $isToddlerMode) {
                HStack(spacing: 12) {
                    Image(systemName: "figure.and.child.holdinghands")
                        .font(.title2)
                        .foregroundColor(.orange)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("For Toddlers")
                            .font(.headline)
                        Text("Simple, bold lines for ages 2-5")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: .orange))
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isToddlerMode ? Color.orange.opacity(0.1) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isToddlerMode ? Color.orange : Color.clear, lineWidth: 2)
            )
            .onChange(of: isToddlerMode) { newValue in
                if newValue {
                    selectedPreset = .toddler
                    thickness = 6
                    detail = 0.2
                } else {
                    selectedPreset = .portrait
                    thickness = 3
                    detail = 0.5
                }
                updatePreview()
            }
        }
    }

    private func imagePreview(_ image: UIImage, label: String) -> some View {
        VStack(spacing: 8) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(height: 150)
                .background(Color.white)
                .cornerRadius(8)
                .shadow(radius: 2)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var nameInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Name Your Coloring Page")
                .font(.subheadline)
                .foregroundColor(.secondary)

            TextField("My Coloring Page", text: $pageName)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                Task { await createColoringPage() }
            } label: {
                HStack {
                    if isProcessing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "wand.and.stars")
                    }
                    Text(isProcessing ? "Creating..." : "Create Coloring Page")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isProcessing || pageName.isEmpty)

            Button("Choose Different Photo") {
                originalPhoto = nil
                lineArtPreview = nil
                selectedItem = nil
            }
            .foregroundColor(.secondary)
        }
    }

    // MARK: - Processing

    private func loadPhoto(from item: PhotosPickerItem?) async {
        guard let item = item else { return }

        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    originalPhoto = image
                    pageName = "My Coloring Page"
                }
                // Run auto-analysis to suggest best engine/preset
                analyzePhotoAndSuggest()
                updatePreview()
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load photo"
                showError = true
            }
        }
    }

    private func updatePreview() {
        guard let photo = originalPhoto else { return }

        Task {
            do {
                let settings = currentSettings()
                let lineArt = try await legacyEngine.extractLines(from: photo, settings: settings)
                await MainActor.run {
                    lineArtPreview = lineArt
                }
            } catch {
                // Silently fail preview - user can still try to create
            }
        }
    }

    private func createColoringPage() async {
        guard let photo = originalPhoto else { return }

        await MainActor.run { isProcessing = true }

        do {
            let settings = currentSettings()
            let lineArt = try await legacyEngine.extractLines(from: photo, settings: settings)

            let page = try UserContentStorage.shared.save(
                lineArt: lineArt,
                originalPhoto: photo,
                name: pageName.isEmpty ? "My Coloring Page" : pageName,
                preset: selectedPreset ?? .portrait
            )

            await MainActor.run {
                isProcessing = false
                onComplete?(page)
                dismiss()
            }
        } catch {
            await MainActor.run {
                isProcessing = false
                errorMessage = "Failed to create coloring page: \(error.localizedDescription)"
                showError = true
            }
        }
    }

    private func currentSettings() -> LineArtSettings {
        // If toddler mode is enabled, always use toddler preset
        if isToddlerMode {
            return LineArtPreset.toddler.settings
        }

        if let preset = selectedPreset {
            return preset.settings
        }

        // Custom settings from sliders
        let maxDimension = Int(384 + detail * 640)  // 384-1024
        let contrastAdjustment = Float(1.0 + detail * 2.0)  // 1.0-3.0
        let closeKernel = thickness >= 4 ? 5 : (thickness >= 3 ? 3 : 1)

        return LineArtSettings(
            maxDimension: maxDimension,
            contrastAdjustment: contrastAdjustment,
            contrastBoost: 1.2 + Float(detail) * 0.2,
            blurAmount: 0,
            engineType: selectedEngine,
            postProcess: LineArtSettings.PostProcessConfig(
                closeKernel: closeKernel,
                thickness: Int(thickness),
                minSpeckleArea: 30,
                simplifyRegions: false,
                minRegionArea: 500
            )
        )
    }

    // MARK: - Auto-Analysis

    /// Analyze photo and suggest best engine/preset
    private func analyzePhotoAndSuggest() {
        guard let photo = originalPhoto else { return }

        Task {
            do {
                let analysis = try await photoAnalyzer.analyze(photo: photo)

                await MainActor.run {
                    // Apply suggestions if not in toddler mode
                    if !isToddlerMode {
                        selectedPreset = analysis.suggestedPreset
                        selectedEngine = analysis.suggestedEngine
                    }
                }
            } catch {
                // Analysis failed - use defaults
            }
        }
    }
}
