# FamilyColorFun - Technical Architecture

## Overview

FamilyColorFun is a SwiftUI-based iOS coloring application designed for children and families. The app uses a modular architecture with clear separation between UI, business logic, and data layers.

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         SwiftUI Views                            │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────────┐   │
│  │ HomeView │ │ Canvas   │ │ Gallery  │ │ PhotoUploadView  │   │
│  │          │ │ View     │ │ View     │ │                  │   │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────────┬─────────┘   │
└───────┼────────────┼────────────┼────────────────┼──────────────┘
        │            │            │                │
┌───────┼────────────┼────────────┼────────────────┼──────────────┐
│       ▼            ▼            ▼                ▼              │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    View Models / State                   │   │
│  │  ┌──────────┐ ┌──────────────┐ ┌─────────────────────┐  │   │
│  │  │FillEngine│ │DrawingEngine │ │ PhotoProcessingVM   │  │   │
│  │  └──────────┘ └──────────────┘ └─────────────────────┘  │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
        │                    │                    │
┌───────┼────────────────────┼────────────────────┼───────────────┐
│       ▼                    ▼                    ▼               │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                       Services                           │   │
│  │ ┌────────────┐ ┌─────────────┐ ┌──────────────────────┐ │   │
│  │ │FloodFill   │ │Storage      │ │ PhotoProcessing      │ │   │
│  │ │Service     │ │Service      │ │ Pipeline             │ │   │
│  │ └────────────┘ └─────────────┘ └──────────────────────┘ │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
        │                    │                    │
┌───────┼────────────────────┼────────────────────┼───────────────┐
│       ▼                    ▼                    ▼               │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    Data Layer                            │   │
│  │  ┌──────────┐ ┌──────────────┐ ┌─────────────────────┐  │   │
│  │  │ Assets   │ │  FileManager │ │  UserDefaults       │  │   │
│  │  │ .xcassets│ │  Documents/  │ │  Settings           │  │   │
│  │  └──────────┘ └──────────────┘ └─────────────────────┘  │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## Core Components

### 1. Fill Engine (`FillEngine.swift`)

The FillEngine manages the tap-to-fill coloring experience.

```swift
class FillEngine: ObservableObject {
    @Published var currentImage: UIImage?
    @Published var progress: Double = 0
    @Published var canUndo: Bool = false

    private var undoStack: [UIImage] = []
    private let maxUndoSteps = 10

    func fill(at point: CGPoint, with color: UIColor)
    func undo()
    func clear()
}
```

**Key Features:**
- Pre-computed region label maps for O(1) region lookup
- Efficient flood fill using scanline algorithm
- 10-step undo stack with memory management
- Progress tracking based on filled vs total regions

**Fill Algorithm:**
```
1. Normalize tap point to image coordinates
2. Look up region ID from label map
3. If region not already filled:
   a. Push current state to undo stack
   b. Apply flood fill with selected color
   c. Update progress percentage
   d. Trigger haptic feedback
```

### 2. Drawing Engine (`DrawingEngine.swift`)

Manages free-hand drawing overlay on coloring pages.

```swift
class DrawingEngine: ObservableObject {
    @Published var paths: [DrawingPath] = []
    @Published var currentPath: DrawingPath?
    @Published var filledAreas: [FilledArea] = []

    func startPath(at point: CGPoint, color: UIColor, lineWidth: CGFloat, isEraser: Bool)
    func addPoint(_ point: CGPoint)
    func endPath()
    func undo()
    func clear()
}
```

**Path Smoothing:**
- Uses Catmull-Rom spline interpolation
- Minimum distance threshold between points (5px)
- Line width based on velocity (pressure simulation)

### 3. Photo Processing Pipeline

The photo-to-coloring feature uses a multi-stage pipeline:

```
┌──────────────────────────────────────────────────────────────┐
│                    Photo Processing Pipeline                  │
│                                                              │
│  ┌─────────┐    ┌─────────────┐    ┌─────────────────────┐  │
│  │  Input  │───▶│ Preprocessor│───▶│ VisionContoursEngine│  │
│  │  Photo  │    │             │    │                     │  │
│  └─────────┘    └─────────────┘    └──────────┬──────────┘  │
│                                               │             │
│                                               ▼             │
│  ┌─────────┐    ┌─────────────┐    ┌─────────────────────┐  │
│  │ Output  │◀───│ Validator   │◀───│  Post-Processor     │  │
│  │LineArt  │    │             │    │                     │  │
│  └─────────┘    └─────────────┘    └─────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
```

#### Stage 1: ImagePreprocessor

```swift
class ImagePreprocessor {
    func resize(_ image: UIImage, maxDimension: Int) -> UIImage
    func increaseContrast(_ image: UIImage, gamma: Float) -> UIImage
    func denoise(_ image: UIImage) -> UIImage
    func gaussianBlur(_ image: UIImage, radius: Float) -> UIImage  // Toddler mode
}
```

**Preprocessing Steps:**
1. Resize to target dimension (256-1024px based on detail setting)
2. Apply Gaussian blur (toddler mode only, radius=3)
3. Contrast enhancement using gamma correction
4. Light denoising to reduce texture

#### Stage 2: VisionContoursEngine

Uses Apple's Vision framework for edge detection:

```swift
class VisionContoursEngine {
    func extractLines(from photo: UIImage, settings: LineArtSettings) async throws -> UIImage {
        // 1. Preprocess image
        let preprocessed = preprocessor.process(photo, settings: settings)

        // 2. Detect polarity (dark-on-light vs light-on-dark)
        let isDarkOnLight = detectPolarity(preprocessed)

        // 3. Create and execute Vision request
        let request = VNDetectContoursRequest()
        request.contrastAdjustment = settings.contrastAdjustment
        request.maximumImageDimension = settings.maxDimension
        request.detectsDarkOnLight = isDarkOnLight

        // 4. Render contours to image
        let contours = try await performRequest(request, on: preprocessed)
        let rendered = renderContours(contours, thickness: settings.thickness)

        // 5. Post-process for fillability
        return fillabilityPostProcess(rendered, settings: settings)
    }
}
```

#### Stage 3: Post-Processing

```swift
private func fillabilityPostProcess(_ image: UIImage, settings: LineArtSettings) -> UIImage {
    var result = image

    // Stage 1: Seal micro-gaps
    result = morphologicalClose(result, kernelSize: 1)

    // Stage 2: Close larger gaps (configurable)
    if settings.closeLargeGaps {
        result = morphologicalClose(result, kernelSize: settings.largeGapKernel)
    }

    // Stage 3: Thicken lines
    result = morphologicalDilate(result, amount: settings.thickness)

    // Stage 4: Binary threshold (no anti-aliasing)
    result = hardThreshold(result, level: 128)

    // Stage 5: Remove noise
    result = removeTinyComponents(result, minArea: settings.minRegionArea)

    // Stage 6: Simplify regions (toddler mode)
    if settings.simplifyRegions {
        result = simplifySmallRegions(result, minArea: settings.minRegionArea)
    }

    return result
}
```

#### Stage 4: FillabilityValidator

Validates output quality for kid-friendly coloring:

```swift
struct FillabilityResult {
    let score: Double           // 0.0-1.0 overall quality
    let regionCount: Int        // Number of fillable regions
    let closureRate: Double     // % of fully enclosed regions
    let leakPotential: Double   // Risk of color leaking
    let tapUsability: Double    // % of regions large enough to tap
    let suggestions: [String]   // Improvement suggestions
}

class FillabilityValidator {
    func evaluate(_ lineArt: UIImage, forToddler: Bool = false) -> FillabilityResult
}
```

**Validation Metrics:**

| Metric | Calculation | Target (Standard) | Target (Toddler) |
|--------|-------------|-------------------|------------------|
| Region Count | Connected components | 50-500 | 10-30 |
| Closure Rate | Enclosed / Total regions | ≥70% | ≥90% |
| Leak Potential | Corner flood fill area | <30% | <10% |
| Tap Usability | Regions ≥ minArea | ≥80% | ≥90% |

### 4. Line Art Settings

```swift
struct LineArtSettings {
    let maxDimension: Int        // 256-1024px
    let contrastAdjustment: Float // 1.0-3.0
    let thickness: Int           // 1-8px line width
    let closeLargeGaps: Bool     // Enable gap closing
    let largeGapKernel: Int      // Morphological kernel size
    let contrastBoost: Float     // Additional contrast
    let blurAmount: Float        // Gaussian blur radius
    let minRegionArea: Int       // Minimum region size
    let simplifyRegions: Bool    // Fill small regions
}

enum LineArtPreset: String, CaseIterable {
    case toddler    // Ages 2-5: Simple, bold
    case portrait   // Face photos
    case landscape  // Scenic views
    case object     // Single objects
    case pet        // Animal photos
    case abstract   // Artistic style
}
```

**Preset Configurations:**

| Preset | maxDim | contrast | thickness | blur | minRegion |
|--------|--------|----------|-----------|------|-----------|
| Toddler | 256 | 1.2 | 6 | 3.0 | 2000 |
| Portrait | 768 | 2.5 | 3 | 0 | 500 |
| Landscape | 512 | 2.0 | 2 | 0 | 500 |
| Object | 768 | 2.8 | 2 | 0 | 500 |
| Pet | 512 | 2.2 | 3 | 0 | 500 |
| Abstract | 384 | 1.5 | 4 | 0 | 500 |

## Data Models

### ColoringPage

```swift
struct ColoringPage: Identifiable, Hashable {
    let id: String
    let name: String
    let imageName: String
    let difficulty: Difficulty
    let regionCount: Int?

    enum Difficulty: String {
        case easy, medium, hard
    }
}
```

### Category

```swift
struct Category: Identifiable, Hashable {
    let id: String
    let name: String
    let icon: String
    let pages: [ColoringPage]
    let isPremium: Bool

    static let all: [Category] = [
        Category(id: "animals", name: "Animals", icon: "hare.fill", pages: ColoringPage.animals),
        // ... 19 more categories
    ]
}
```

### DrawingPath

```swift
struct DrawingPath: Identifiable {
    let id: UUID
    var points: [CGPoint]
    let color: UIColor
    let lineWidth: CGFloat
    let isEraser: Bool
}
```

## File Structure

```
FamilyColorFun/
├── FamilyColorFunApp.swift          # App entry point
├── ContentView.swift                 # Root navigation
│
├── Models/
│   ├── ColoringPage.swift           # 250+ page definitions
│   ├── Category.swift               # 20 category definitions
│   ├── DrawingPath.swift            # Stroke model
│   └── UserGeneratedPage.swift      # User uploads
│
├── Views/
│   ├── HomeView.swift               # Category grid (Material 3)
│   ├── CategoryView.swift           # Page thumbnails
│   ├── CanvasView.swift             # Main coloring interface
│   ├── GalleryView.swift            # Saved artwork browser
│   ├── PhotoUploadView.swift        # Photo import flow
│   ├── AdjustmentSliders.swift      # Photo settings controls
│   └── Components/
│       ├── TapFillCanvas.swift      # Fill interaction layer
│       ├── DrawingCanvas.swift      # Drawing overlay
│       ├── ColorPalette.swift       # Color picker
│       └── ProgressIndicator.swift  # Completion progress
│
├── Services/
│   ├── FloodFillService.swift       # Fill algorithm
│   ├── StorageService.swift         # Persistence
│   ├── SoundManager.swift           # Audio feedback
│   └── PhotoProcessing/
│       ├── Protocols/
│       │   └── LineArtEngineProtocol.swift
│       ├── Engines/
│       │   └── VisionContoursEngine.swift
│       ├── Preprocessing/
│       │   └── ImagePreprocessor.swift
│       ├── Settings/
│       │   └── LineArtSettings.swift
│       ├── Validation/
│       │   └── FillabilityValidator.swift
│       └── Storage/
│           └── UserContentStorage.swift
│
├── Engines/
│   ├── FillEngine.swift             # Tap-to-fill state
│   └── DrawingEngine.swift          # Drawing state
│
├── Assets.xcassets/
│   ├── ColoringPages/               # 70+ line art images
│   └── PageMetadata/                # Region label maps
│
└── scripts/
    ├── add_borders.py               # Image processing
    ├── generate_new_categories.py   # Procedural generation
    └── generate_improved_animals.py # Animal artwork
```

## Performance Considerations

### Memory Management
- Lazy loading of images (only load when visible)
- Image downsampling for thumbnails
- Undo stack limited to 10 states
- Automatic cache cleanup on memory warning

### Rendering Optimization
- Metal-backed Core Image filters
- Async image processing off main thread
- Pre-rendered region maps stored as metadata
- Incremental rendering for large images

### Battery Efficiency
- No background processing
- Minimal use of GPS/network
- Efficient flood fill (scanline algorithm)
- Throttled gesture updates

## Testing Strategy

### Unit Tests
- Model serialization/deserialization
- Fill engine state transitions
- Drawing engine path management
- Photo processing pipeline stages

### Integration Tests
- End-to-end photo conversion
- Fill + undo sequences
- Category navigation flows

### Performance Tests
- Fill operation timing (<100ms target)
- Photo processing timing (<1s target)
- Memory usage during coloring

### UI Tests
- Category browsing
- Page selection
- Color selection
- Save/share flows

## Security & Privacy

- **No network calls**: All processing on-device
- **No analytics**: No tracking or telemetry
- **No ads**: Clean user experience
- **Photo access**: Only when user initiates upload
- **File storage**: App sandbox only
- **COPPA compliant**: No data collection from children

## Future Considerations

### Potential Enhancements
1. **ML-based line extraction**: HED/Anime2Sketch models
2. **Cloud sync**: Family sharing of artwork
3. **AR mode**: Color in 3D space
4. **Social features**: Share galleries
5. **Premium content**: Additional categories

### Scalability
- Modular architecture supports new engines
- Protocol-based services for easy mocking/testing
- Asset catalog structure supports 1000+ images
- Lazy loading prevents memory issues at scale
