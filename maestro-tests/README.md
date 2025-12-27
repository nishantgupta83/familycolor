# FamilyColorFun Maestro Test Suite

Comprehensive UI test suite using [Maestro](https://maestro.mobile.dev/) for automated testing of all screen workflows.

## Prerequisites

### Install Maestro

```bash
curl -Ls "https://get.maestro.mobile.dev" | bash
```

### Verify Installation

```bash
maestro --version
```

## Test Structure

```
maestro-tests/
├── config.yaml              # Global configuration
├── run_all_tests.sh         # Master test runner script
├── README.md                # This file
├── flows/                   # Individual test flows
│   ├── 01_app_launch.yaml
│   ├── 02_home_screen.yaml
│   ├── 03_category_navigation.yaml
│   ├── 04_canvas_coloring.yaml
│   ├── 05_canvas_zoom.yaml
│   ├── 06_gallery.yaml
│   ├── 07_settings.yaml
│   ├── 08_color_suggestions.yaml
│   ├── 09_photo_upload.yaml
│   ├── 10_progression_system.yaml
│   ├── 11_companion_system.yaml
│   └── 12_end_to_end.yaml
├── screenshots/             # Test screenshots (generated)
└── reports/                 # JUnit XML reports (generated)
```

## Test Coverage

| Test | Description | Tags |
|------|-------------|------|
| 01_app_launch | App launch and initial state | smoke, launch |
| 02_home_screen | Home screen elements and categories | home, navigation |
| 03_category_navigation | Navigate between categories | navigation, categories |
| 04_canvas_coloring | Fill/Draw mode, color palette, tools | canvas, coloring, core |
| 05_canvas_zoom | Zoom in/out, pan controls | canvas, zoom |
| 06_gallery | Artwork gallery, badges | gallery, artwork |
| 07_settings | Color palette, age mode, toggles | settings, preferences |
| 08_color_suggestions | AI color suggestions feature | suggestions, ai |
| 09_photo_upload | Custom photo upload flow | upload, photo |
| 10_progression_system | Stars, locked pages, unlocking | progression, stars |
| 11_companion_system | Buddy companion dialogues | companion, buddy |
| 12_end_to_end | Complete user journey | e2e, complete |

## Running Tests

### Run All Tests

```bash
# Make script executable
chmod +x maestro-tests/run_all_tests.sh

# Run all tests
./maestro-tests/run_all_tests.sh
```

### Run Smoke Tests Only

```bash
./maestro-tests/run_all_tests.sh --smoke
```

### Run a Single Test

```bash
./maestro-tests/run_all_tests.sh --test 04_canvas_coloring.yaml
```

### Run Tests Directly with Maestro

```bash
# Run single flow
maestro test maestro-tests/flows/01_app_launch.yaml

# Run all flows in directory
maestro test maestro-tests/flows/

# Run with specific device
maestro test --device "iPhone 16" maestro-tests/flows/
```

## Interactive Testing

### Maestro Studio

Launch interactive mode to explore the app and build tests:

```bash
maestro studio
```

### Record a Flow

Record interactions to create new tests:

```bash
maestro record maestro-tests/flows/new_test.yaml
```

## Viewing Results

### Screenshots

Screenshots are saved to `maestro-tests/screenshots/` with naming convention:
- `{test_number}_{description}.png`

### JUnit Reports

XML reports compatible with CI/CD systems are saved to `maestro-tests/reports/`:
- `{test_name}.xml`

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Maestro Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Maestro
        run: curl -Ls "https://get.maestro.mobile.dev" | bash

      - name: Build App
        run: |
          xcodebuild -project FamilyColorFun.xcodeproj \
            -scheme FamilyColorFun \
            -destination 'platform=iOS Simulator,name=iPhone 16' \
            build

      - name: Boot Simulator
        run: |
          xcrun simctl boot "iPhone 16"
          xcrun simctl install booted build/Debug-iphonesimulator/FamilyColorFun.app

      - name: Run Maestro Tests
        run: ./maestro-tests/run_all_tests.sh

      - name: Upload Screenshots
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: maestro-screenshots
          path: maestro-tests/screenshots/

      - name: Upload Reports
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: maestro-reports
          path: maestro-tests/reports/
```

## Tips

### Debugging Failed Tests

1. Run the failing test with `--debug`:
   ```bash
   maestro test --debug flows/04_canvas_coloring.yaml
   ```

2. Use Maestro Studio to explore the current app state:
   ```bash
   maestro studio
   ```

3. Check screenshots in `maestro-tests/screenshots/`

### Common Issues

| Issue | Solution |
|-------|----------|
| Element not found | Increase timeout or use `extendedWaitUntil` |
| App not launching | Ensure app is installed on simulator |
| Tests timing out | Increase global timeout in config.yaml |

## Workflows Tested

### Home Screen Flow
- App launch → Home screen loads
- Category cards visible
- Settings button works
- "Create Your Own" card visible

### Category Flow
- Navigate to category → Page grid loads
- Stars header visible
- Locked pages show lock icons
- Back navigation works

### Canvas Flow
- Open coloring page → Canvas loads
- Fill mode: tap to color regions
- Draw mode: pencil/brush tools
- Zoom: in/out/pan/reset
- Color palette selection
- Undo/clear buttons
- Exit with save dialog

### Gallery Flow
- View saved artworks
- Badge system (Beginner → Master)
- Empty state handling

### Settings Flow
- Color palette selection
- Age mode toggle
- Sound/haptic toggles
- Parent Zone access

### AI Features
- Color suggestions overlay
- Companion (Buddy) dialogues
- Progress milestones

## Contributing

When adding new tests:

1. Follow naming convention: `{number}_{feature}.yaml`
2. Add appropriate tags (smoke, e2e, etc.)
3. Include screenshots at key points
4. Update this README with test description
