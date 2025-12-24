# FamilyColorFun

A delightful iOS coloring app designed for kids and families. Features tap-to-fill coloring, drawing mode, photo-to-coloring page conversion, and a special **Toddler Mode** optimized for ages 2-5.

## Features

### Core Coloring
- **Tap-to-Fill**: Simply tap any region to fill it with the selected color
- **Drawing Mode**: Free-hand drawing with adjustable brush sizes
- **Undo/Redo**: Full undo history for mistakes
- **Auto-Complete**: Automatically suggests filling remaining regions at 90%+ progress
- **Save & Share**: Export completed artwork to Photos or share directly

### Photo-to-Coloring (NEW)
- Upload any photo and convert it to a coloring page
- Vision framework-based line art extraction
- **Toddler Mode**: Optimized for ages 2-5 with:
  - Bold, thick lines (6-8px)
  - Simplified shapes (10-25 regions vs 100+)
  - Large tap targets for little fingers
  - 100% closure rate (no color leaks)
- Adjustable thickness and detail settings
- Preset modes: Toddler, Portrait, Landscape, Object, Pet, Abstract

### Categories (20 Total)
| Category | Pages | Category | Pages |
|----------|-------|----------|-------|
| Animals | 7 | Dinosaurs | 3 |
| Vehicles | 1 | Space | 3 |
| Houses | 1 | Food | 3 |
| Nature | 5 | Holidays | 3 |
| Ocean | 1 | Sports | 3 |
| Retro 90s | 2 | Music | 3 |
| Mandalas | 6 | Robots | 3 |
| Geometric | 6 | Fantasy | 3 |
| Abstract | 2 | Underwater | 3 |
| Zen Patterns | 3 | Portraits | 3 |

## Requirements

- iOS 16.0+
- Xcode 15.0+
- Swift 5.9+

## Installation

1. Clone the repository:
```bash
git clone https://github.com/nishantgupta83/familycolorfun.git
cd familycolorfun
```

2. Open the project in Xcode:
```bash
open FamilyColorFun.xcodeproj
```

3. Build and run on simulator or device (Cmd+R)

## Project Structure

```
FamilyColorFun/
├── Models/
│   ├── ColoringPage.swift       # Page definitions
│   ├── Category.swift           # Category definitions
│   ├── DrawingPath.swift        # Drawing stroke model
│   └── UserGeneratedPage.swift  # User-uploaded pages
├── Views/
│   ├── HomeView.swift           # Main category grid
│   ├── CategoryView.swift       # Page selection
│   ├── CanvasView.swift         # Coloring canvas
│   ├── GalleryView.swift        # Saved artwork
│   ├── PhotoUploadView.swift    # Photo upload flow
│   └── Components/
│       ├── TapFillCanvas.swift  # Fill engine
│       ├── DrawingCanvas.swift  # Drawing layer
│       └── ColorPalette.swift   # Color selector
├── Services/
│   ├── FloodFillService.swift   # Flood fill algorithm
│   ├── StorageService.swift     # Artwork persistence
│   ├── SoundManager.swift       # Audio feedback
│   └── PhotoProcessing/         # Photo-to-coloring
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
├── Assets.xcassets/
│   ├── ColoringPages/           # Line art images
│   └── PageMetadata/            # Region metadata
└── scripts/
    ├── add_borders.py           # Border processing
    ├── generate_new_categories.py
    └── generate_improved_animals.py
```

## Testing

### Run All Tests
```bash
xcodebuild test -project FamilyColorFun.xcodeproj -scheme FamilyColorFun -destination 'platform=iOS Simulator,name=iPhone 16'
```

### Test Suites

| Suite | Tests | Description |
|-------|-------|-------------|
| FamilyColorFunTests | 28 | Unit tests for models and services |
| StateManagementTests | 20 | FillEngine and DrawingEngine tests |
| PerformanceTests | 8 | Performance benchmarks |
| ColoringAppQATests | 50 | Comprehensive QA test cases |
| ComprehensivePageTests | 65+ | All pages navigation and fill |

### Run Specific Test Batches
```bash
# Unit tests only
xcodebuild test -only-testing:FamilyColorFunTests ...

# State management tests
xcodebuild test -only-testing:FamilyColorFunTests/StateManagementTests ...

# QA tests only
xcodebuild test -only-testing:FamilyColorFunUITests/ColoringAppQATests ...
```

## Scripts

### Add Borders to Images
Prevents color bleeding by adding borders to coloring pages:
```bash
cd scripts
python3 add_borders.py --assets ../FamilyColorFun/Assets.xcassets
```

### Generate Animal Images
Creates improved cartoon-style animal coloring pages:
```bash
python3 generate_improved_animals.py
python3 add_borders.py --raw raw_downloads/improved_animals
```

### Generate New Category Images
Creates procedural coloring pages for various categories:
```bash
python3 generate_new_categories.py
```

## Key Technologies

- **SwiftUI**: Modern declarative UI framework
- **Vision Framework**: On-device contour detection for photo-to-coloring
- **Core Image**: Image preprocessing and morphological operations
- **Accelerate**: High-performance flood fill algorithms
- **PhotosUI**: Native photo picker integration

## Architecture Highlights

### Fill Engine
- Uses pre-computed region label maps for instant fills
- Supports up to 500+ regions per page
- Memory-efficient with lazy loading
- 10-step undo stack

### Photo Processing Pipeline
1. **Preprocessing**: Resize, Gaussian blur (toddler mode), contrast enhancement
2. **Line Extraction**: Vision framework contour detection with polarity detection
3. **Post-processing**: Morphological close, dilate, threshold, noise removal
4. **Region Simplification**: Fills small regions for toddler-friendly output
5. **Validation**: Region count, closure rate, leak potential, tap usability

### Toddler Mode Optimization
| Parameter | Toddler | Standard |
|-----------|---------|----------|
| Max Dimension | 256px | 768px |
| Line Thickness | 6-8px | 2-3px |
| Min Region Area | 2000px | 500px |
| Target Regions | 10-25 | 50-500 |
| Closure Rate | 100% | 70%+ |

## Privacy & Compliance

- **No data collection**: All processing happens on-device
- **No network calls**: Works completely offline
- **COPPA compliant**: Safe for children under 13
- **No ads**: Clean, distraction-free experience

## License

MIT License - See LICENSE file for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Run tests to ensure everything passes
4. Submit a pull request

## Contact

For questions or feedback, open an issue on GitHub.
