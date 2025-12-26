import SwiftUI
import PencilKit

struct CanvasView: View {
    let page: ColoringPage
    let category: Category

    @StateObject private var fillEngine: FillEngine
    @State private var selectedColor: Color = .kidColors[0]
    @State private var showShareSheet = false
    @State private var showCompletion = false
    @State private var showAutofillConfirmation = false

    // Phase 2: Mode toggle
    @State private var coloringMode: ColoringMode = .fill
    @State private var drawing = PKDrawing()
    @State private var pencilTool: PencilKitCanvas.PencilTool = .pen
    @State private var brushWidth: CGFloat = 10

    // Drawing undo stack
    @State private var drawingUndoStack: [PKDrawing] = []
    @State private var lastStrokeCount: Int = 0

    // Zoom and pan controls
    @State private var canvasScale: CGFloat = 1.0
    @State private var canvasOffset: CGSize = .zero
    @State private var isPanMode: Bool = false

    // Exit confirmation
    @State private var showExitConfirmation = false

    // Auto-complete hint tracking
    @State private var hasShownAutofillHint = false
    private let autofillThreshold: Double = 0.90 // 90% threshold for auto-fill suggestion

    // Milestone dialogue tracking
    @State private var triggeredMilestones: Set<Int> = []

    // Color suggestion state
    @State private var showColorSuggestions = false
    @ObservedObject private var suggestionService = ColorSuggestionService.shared
    @ObservedObject private var settingsManager = SettingsManager.shared

    @Environment(\.dismiss) private var dismiss

    private var hasUnsavedChanges: Bool {
        fillEngine.regionProgress > 0 || !drawing.strokes.isEmpty
    }

    enum ColoringMode: String, CaseIterable {
        case fill = "Fill"
        case draw = "Draw"
    }

    init(page: ColoringPage, category: Category) {
        self.page = page
        self.category = category
        // Try to load actual image, fallback to placeholder
        let pageImage = UIImage(named: page.imageName) ?? Self.createPlaceholderImage()

        // Load metadata and label-map for intelligent region detection
        let metadata = ColoringPageMetadata.load(for: page.imageName)
        let labelMap: UIImage? = {
            if let labelMapName = metadata?.labelMapName {
                return UIImage(named: labelMapName)
            }
            return nil
        }()

        _fillEngine = StateObject(wrappedValue: FillEngine(
            image: pageImage,
            metadata: metadata,
            labelMap: labelMap
        ))
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Mode selector (Phase 2)
                Picker("Mode", selection: $coloringMode) {
                    ForEach(ColoringMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // Canvas area with floating zoom controls
                ZStack {
                    // Main canvas
                    ZStack {
                        // Fill mode canvas
                        TapFillCanvas(
                            pageImage: fillEngine.currentImage,
                            selectedColor: $selectedColor,
                            fillEngine: fillEngine,
                            externalScale: $canvasScale,
                            externalOffset: $canvasOffset
                        )
                        .allowsHitTesting(coloringMode == .fill && !isPanMode)

                        // Draw mode overlay (Phase 2)
                        if coloringMode == .draw {
                            PencilKitCanvas(
                                drawing: $drawing,
                                toolColor: $selectedColor,
                                toolWidth: $brushWidth,
                                currentTool: $pencilTool,
                                backgroundImage: nil,
                                onDrawingChanged: { newDrawing in
                                    // Push to undo stack when stroke is added
                                    if newDrawing.strokes.count > lastStrokeCount {
                                        // Save previous state before this stroke
                                        var previousDrawing = newDrawing
                                        if !previousDrawing.strokes.isEmpty {
                                            previousDrawing.strokes.removeLast()
                                        }
                                        drawingUndoStack.append(previousDrawing)
                                        if drawingUndoStack.count > 10 {
                                            drawingUndoStack.removeFirst()
                                        }
                                    }
                                    lastStrokeCount = newDrawing.strokes.count
                                }
                            )
                            .scaleEffect(canvasScale)
                            .offset(canvasOffset)
                            .allowsHitTesting(!isPanMode)
                        }

                        // Pan gesture overlay when pan mode is active
                        if isPanMode && canvasScale > 1.0 {
                            Color.clear
                                .contentShape(Rectangle())
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            canvasOffset = CGSize(
                                                width: canvasOffset.width + value.translation.width,
                                                height: canvasOffset.height + value.translation.height
                                            )
                                        }
                                        .onEnded { _ in }
                                )
                        }

                        // Progress hint
                        if fillEngine.progress > 0.5 && coloringMode == .fill {
                            ProgressHintOverlay(progress: fillEngine.progress)
                        }

                        // Completion animation
                        if showCompletion {
                            CompletionOverlay()
                        }

                        // Color suggestion overlay
                        if showColorSuggestions && suggestionService.isShowingSuggestions {
                            GeometryReader { canvasGeometry in
                                ColorSuggestionOverlay(
                                    suggestions: suggestionService.currentSuggestions,
                                    imageSize: fillEngine.metadata?.imageSize ?? CGSize(width: 1024, height: 1024),
                                    displaySize: canvasGeometry.size,
                                    onTapSuggestion: { suggestion in
                                        let imageSize = fillEngine.metadata?.imageSize ?? CGSize(width: 1024, height: 1024)
                                        suggestionService.applySuggestion(suggestion, to: fillEngine, imageSize: imageSize)
                                        selectedColor = suggestion.suggestedColor

                                        // Reset idle timer
                                        startIdleTimer()
                                    },
                                    onDismiss: {
                                        showColorSuggestions = false
                                        suggestionService.hideSuggestions()
                                        startIdleTimer()
                                    }
                                )
                            }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.1), radius: 4)

                    // Floating zoom controls (bottom-right)
                    VStack(spacing: 8) {
                        Spacer()
                        HStack {
                            Spacer()
                            VStack(spacing: 6) {
                                // Pan mode toggle (only when zoomed)
                                if canvasScale > 1.0 {
                                    Button {
                                        isPanMode.toggle()
                                        SoundManager.shared.playTap()
                                    } label: {
                                        Image(systemName: isPanMode ? "hand.raised.fill" : "hand.raised")
                                            .font(.title3)
                                            .foregroundStyle(isPanMode ? .white : category.color)
                                            .frame(width: 40, height: 40)
                                            .background(Circle().fill(isPanMode ? category.color : Color(.systemBackground)))
                                            .shadow(color: .black.opacity(0.15), radius: 3, y: 2)
                                    }
                                }

                                // Zoom in
                                Button {
                                    withAnimation(.spring(response: 0.3)) {
                                        canvasScale = min(canvasScale + 0.5, 3.0)
                                    }
                                    SoundManager.shared.playTap()
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.title3.bold())
                                        .foregroundStyle(canvasScale < 3.0 ? category.color : .gray.opacity(0.3))
                                        .frame(width: 40, height: 40)
                                        .background(Circle().fill(Color(.systemBackground)))
                                        .shadow(color: .black.opacity(0.15), radius: 3, y: 2)
                                }
                                .disabled(canvasScale >= 3.0)

                                // Zoom percentage / reset
                                Button {
                                    withAnimation(.spring(response: 0.3)) {
                                        canvasScale = 1.0
                                        canvasOffset = .zero
                                        isPanMode = false
                                    }
                                    SoundManager.shared.playTap()
                                } label: {
                                    Text("\(Int(canvasScale * 100))%")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(canvasScale != 1.0 ? category.color : .secondary)
                                        .frame(width: 40, height: 40)
                                        .background(Circle().fill(Color(.systemBackground)))
                                        .shadow(color: .black.opacity(0.15), radius: 3, y: 2)
                                }

                                // Zoom out
                                Button {
                                    withAnimation(.spring(response: 0.3)) {
                                        canvasScale = max(canvasScale - 0.5, 1.0)
                                        if canvasScale == 1.0 {
                                            canvasOffset = .zero
                                            isPanMode = false
                                        }
                                    }
                                    SoundManager.shared.playTap()
                                } label: {
                                    Image(systemName: "minus")
                                        .font(.title3.bold())
                                        .foregroundStyle(canvasScale > 1.0 ? category.color : .gray.opacity(0.3))
                                        .frame(width: 40, height: 40)
                                        .background(Circle().fill(Color(.systemBackground)))
                                        .shadow(color: .black.opacity(0.15), radius: 3, y: 2)
                                }
                                .disabled(canvasScale <= 1.0)
                            }
                            .padding(8)
                        }
                    }
                    .padding(.trailing, 8)
                    .padding(.bottom, 8)
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)

                // Toolbar
                VStack(spacing: 8) {
                    ColorPalette(selectedColor: $selectedColor)

                    // Mode-specific tools
                    if coloringMode == .fill {
                        fillModeToolbar
                    } else {
                        drawModeToolbar
                    }
                }
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(page.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: Button {
            shareArtwork()
        } label: {
            Image(systemName: "square.and.arrow.up")
        })
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [mergeDrawingWithFill()])
        }
        .onChange(of: fillEngine.regionProgress) { newValue in
            handleProgressChange(regionProgress: newValue)

            // Reset idle timer on user activity
            startIdleTimer()

            // Hide suggestions if user is actively filling
            if showColorSuggestions {
                showColorSuggestions = false
                suggestionService.hideSuggestions()
            }
        }
        .confirmationDialog(
            "Fill all remaining regions?",
            isPresented: $showAutofillConfirmation,
            titleVisibility: .visible
        ) {
            Button("Fill with random colors") {
                fillEngine.fillAllRemaining(palette: SettingsManager.shared.currentColors)
                SoundManager.shared.playFill()
            }
            Button("Cancel", role: .cancel) {
                showAutofillConfirmation = false
            }
        } message: {
            let remaining = (fillEngine.metadata?.totalRegions ?? 0) - fillEngine.regionProgress
            Text("This will fill \(remaining) unfilled regions. Already colored areas will NOT change.")
        }
        .confirmationDialog(
            "You have unsaved changes",
            isPresented: $showExitConfirmation,
            titleVisibility: .visible
        ) {
            Button("Save & Exit") {
                shareArtwork()
                dismiss()
            }
            Button("Exit without saving", role: .destructive) {
                dismiss()
            }
            Button("Cancel", role: .cancel) {
                showExitConfirmation = false
            }
        } message: {
            Text("Would you like to save your artwork before leaving?")
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    if hasUnsavedChanges {
                        showExitConfirmation = true
                    } else {
                        dismiss()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .fontWeight(.semibold)
                        Text(category.name)
                    }
                    .foregroundStyle(category.color)
                }
            }
        }
        .onAppear {
            // Start or resume journey session
            JourneyStore.shared.startOrResume(pageId: page.id.uuidString)
            CompanionController.shared.trigger(.start, pageName: page.name)

            // Start idle timer for color suggestions
            startIdleTimer()
        }
        .onDisappear {
            // End journey session
            JourneyStore.shared.endSession(pageId: page.id.uuidString)

            // Stop idle timer
            stopIdleTimer()
        }
    }

    // MARK: - Fill Mode Toolbar
    private var fillModeToolbar: some View {
        HStack(spacing: 24) {
            ToolButton(
                icon: "arrow.uturn.backward.circle.fill",
                isEnabled: fillEngine.canUndo,
                color: category.color
            ) {
                fillEngine.undo()
                SoundManager.shared.playTap()
            }

            ToolButton(
                icon: "trash.circle.fill",
                isEnabled: true,
                color: .red.opacity(0.7)
            ) {
                fillEngine.clear()
                SoundManager.shared.playTap()
            }

            // AUTOFILL BUTTON
            ToolButton(
                icon: "wand.and.stars",
                isEnabled: fillEngine.regionProgress < (fillEngine.metadata?.totalRegions ?? 0),
                color: .yellow
            ) {
                showAutofillConfirmation = true
                SoundManager.shared.playTap()
            }
            .accessibilityLabel("Fill remaining regions")

            // COLOR HELP BUTTON
            if settingsManager.colorSuggestionsEnabled {
                ToolButton(
                    icon: "questionmark.circle.fill",
                    isEnabled: fillEngine.regionProgress < (fillEngine.metadata?.totalRegions ?? 0),
                    color: .blue
                ) {
                    triggerColorSuggestions()
                }
                .accessibilityLabel("Show color suggestions")
            }

            Spacer()

            // Show region-based progress if metadata available
            if let totalRegions = fillEngine.metadata?.totalRegions, totalRegions > 0 {
                HStack(spacing: 6) {
                    Text("\(fillEngine.regionProgress)/\(totalRegions)")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(category.color)

                    Image(systemName: "paintpalette.fill")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            } else {
                // Fallback to percentage-based progress
                ProgressView(value: fillEngine.progress)
                    .progressViewStyle(.linear)
                    .frame(width: 80)
                    .tint(category.color)

                Text("\(Int(fillEngine.progress * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Draw Mode Toolbar (Phase 2)
    private var drawModeToolbar: some View {
        HStack(spacing: 12) {
            // Undo button
            Button {
                undoDrawing()
                SoundManager.shared.playTap()
            } label: {
                Image(systemName: "arrow.uturn.backward.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(!drawingUndoStack.isEmpty ? category.color : .gray.opacity(0.3))
            }
            .disabled(drawingUndoStack.isEmpty)

            // Clear drawing
            Button {
                clearDrawing()
                SoundManager.shared.playTap()
            } label: {
                Image(systemName: "trash.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.red.opacity(0.7))
            }

            Divider().frame(height: 30)

            // Tool buttons
            ForEach([
                (PencilKitCanvas.PencilTool.pen, "pencil.tip"),
                (.pencil, "pencil"),
                (.marker, "highlighter"),
                (.eraser, "eraser")
            ], id: \.1) { tool, icon in
                Button {
                    pencilTool = tool
                    SoundManager.shared.playTap()
                } label: {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(pencilTool == tool ? .white : .primary)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(pencilTool == tool ? category.color : Color(.systemGray5))
                        )
                }
            }

            Spacer()

            // Brush size slider
            HStack(spacing: 4) {
                Circle().fill(category.color).frame(width: 6, height: 6)
                Slider(value: $brushWidth, in: 2...30)
                    .frame(width: 60)
                    .tint(category.color)
                Circle().fill(category.color).frame(width: 14, height: 14)
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Drawing Undo
    private func undoDrawing() {
        guard let previous = drawingUndoStack.popLast() else { return }
        drawing = previous
        lastStrokeCount = drawing.strokes.count
    }

    private func clearDrawing() {
        if !drawing.strokes.isEmpty {
            drawingUndoStack.append(drawing)
            if drawingUndoStack.count > 10 {
                drawingUndoStack.removeFirst()
            }
        }
        drawing = PKDrawing()
        lastStrokeCount = 0
    }

    // MARK: - Actions
    private func shareArtwork() {
        // Merge filled image with PencilKit drawing
        let finalImage = mergeDrawingWithFill()

        _ = StorageService.shared.saveArtwork(
            image: finalImage,
            page: page,
            category: category,
            progress: fillEngine.progress
        )
        showShareSheet = true
    }

    /// Handle progress changes and award milestones
    private func handleProgressChange(regionProgress: Int) {
        // Check completion based on region count if metadata available
        if let totalRegions = fillEngine.metadata?.totalRegions, totalRegions > 0 {
            let progressPercent = Double(regionProgress) / Double(totalRegions)

            // Award milestone stars (25%, 50%, 75%)
            ProgressionEngine.shared.awardProgressMilestone(pageId: page.id.uuidString, progress: progressPercent)

            // Update journey progress
            JourneyStore.shared.updateProgress(progressPercent, for: page.id.uuidString)

            // Trigger companion dialogues at milestones
            triggerMilestoneDialogue(progress: progressPercent)

            // Auto-show autofill suggestion at 90%+ progress
            if progressPercent >= autofillThreshold &&
               !hasShownAutofillHint &&
               regionProgress < totalRegions &&
               coloringMode == .fill {
                hasShownAutofillHint = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showAutofillConfirmation = true
                    SoundManager.shared.playTap()
                }
            }

            // Check for full completion
            if regionProgress >= totalRegions && !showCompletion && coloringMode == .fill {
                withAnimation(.spring()) {
                    showCompletion = true
                }
                SoundManager.shared.playCelebration()

                // Award completion stars and mark journey complete
                ProgressionEngine.shared.onPageComplete(pageId: page.id.uuidString, categoryId: category.categoryId)
                JourneyStore.shared.markComplete(pageId: page.id.uuidString)
            }
        } else if fillEngine.progress >= 1.0 && !showCompletion && coloringMode == .fill {
            withAnimation(.spring()) {
                showCompletion = true
            }
            SoundManager.shared.playCelebration()

            // Award completion for pixel-based progress
            ProgressionEngine.shared.onPageComplete(pageId: page.id.uuidString, categoryId: category.categoryId)
            JourneyStore.shared.markComplete(pageId: page.id.uuidString)
        }
    }

    /// Trigger companion dialogue at milestone thresholds
    private func triggerMilestoneDialogue(progress: Double) {
        if progress >= 0.25 && progress < 0.50 && !triggeredMilestones.contains(25) {
            triggeredMilestones.insert(25)
            CompanionController.shared.trigger(.progress25, pageName: page.name)
        } else if progress >= 0.50 && progress < 0.75 && !triggeredMilestones.contains(50) {
            triggeredMilestones.insert(50)
            CompanionController.shared.trigger(.progress50, pageName: page.name)
        } else if progress >= 0.75 && progress < 1.0 && !triggeredMilestones.contains(75) {
            triggeredMilestones.insert(75)
            CompanionController.shared.trigger(.progress75, pageName: page.name)
        }
    }

    // MARK: - Color Suggestions

    /// Trigger color suggestions (manual or automatic)
    private func triggerColorSuggestions() {
        guard settingsManager.colorSuggestionsEnabled else { return }
        guard fillEngine.regionProgress < (fillEngine.metadata?.totalRegions ?? 0) else { return }

        let suggestions = suggestionService.generateSuggestions(
            fillEngine: fillEngine,
            pageName: page.name,
            categoryId: category.categoryId,
            mode: settingsManager.colorSuggestionMode,
            palette: settingsManager.currentColors
        )

        guard !suggestions.isEmpty else { return }

        suggestionService.showSuggestions(suggestions)
        showColorSuggestions = true

        // Trigger companion dialogue
        CompanionController.shared.trigger(.colorHint, pageName: page.name)
    }

    /// Start the idle timer for automatic suggestions
    private func startIdleTimer() {
        guard settingsManager.colorSuggestionsEnabled else { return }

        suggestionService.startIdleTimer { [self] in
            // Only trigger if in fill mode and not already showing suggestions
            if coloringMode == .fill && !showColorSuggestions {
                triggerColorSuggestions()
            }
        }
    }

    /// Stop the idle timer
    private func stopIdleTimer() {
        suggestionService.stopIdleTimer()
    }

    /// Merge the PencilKit drawing layer with the filled image
    private func mergeDrawingWithFill() -> UIImage {
        let baseImage = fillEngine.currentImage

        // If no drawing strokes, return base image
        guard !drawing.strokes.isEmpty else { return baseImage }

        let size = baseImage.size
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            // Draw the filled base image
            baseImage.draw(at: .zero)

            // Render PencilKit drawing on top
            let drawingBounds = CGRect(origin: .zero, size: size)
            let drawingImage = drawing.image(from: drawingBounds, scale: baseImage.scale)
            drawingImage.draw(in: drawingBounds)
        }
    }

    private static func createPlaceholderImage() -> UIImage {
        let size = CGSize(width: 1024, height: 1024)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            UIColor.black.setStroke()
            let path = UIBezierPath()
            path.lineWidth = 4

            // Circle
            path.append(UIBezierPath(ovalIn: CGRect(x: 200, y: 200, width: 250, height: 250)))
            // Square
            path.append(UIBezierPath(rect: CGRect(x: 550, y: 200, width: 250, height: 250)))
            // Triangle
            path.move(to: CGPoint(x: 325, y: 550))
            path.addLine(to: CGPoint(x: 200, y: 800))
            path.addLine(to: CGPoint(x: 450, y: 800))
            path.close()
            // Star shape
            path.move(to: CGPoint(x: 675, y: 550))
            path.addLine(to: CGPoint(x: 550, y: 800))
            path.addLine(to: CGPoint(x: 800, y: 650))
            path.addLine(to: CGPoint(x: 550, y: 650))
            path.addLine(to: CGPoint(x: 800, y: 800))
            path.close()

            path.stroke()
        }
    }
}

// MARK: - Tool Button
struct ToolButton: View {
    let icon: String
    let isEnabled: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(isEnabled ? color : .gray.opacity(0.3))
        }
        .disabled(!isEnabled)
    }
}

// MARK: - Completion Overlay
struct CompletionOverlay: View {
    @State private var particles: [Particle] = []

    var body: some View {
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
            createParticles()
        }
    }

    private func createParticles() {
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
        for _ in 0..<50 {
            let particle = Particle(
                color: colors.randomElement()!,
                size: CGFloat.random(in: 8...16),
                position: CGPoint(x: CGFloat.random(in: 0...UIScreen.main.bounds.width), y: -20),
                opacity: 1.0
            )
            particles.append(particle)
        }

        for i in particles.indices {
            let delay = Double.random(in: 0...0.5)
            withAnimation(.easeOut(duration: 2.0).delay(delay)) {
                particles[i].position.y = UIScreen.main.bounds.height + 50
                particles[i].opacity = 0
            }
        }
    }
}

struct Particle: Identifiable {
    let id = UUID()
    let color: Color
    let size: CGFloat
    var position: CGPoint
    var opacity: Double
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        CanvasView(page: ColoringPage.animals[0], category: Category.all[0])
    }
}
