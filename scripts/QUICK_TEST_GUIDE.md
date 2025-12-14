# Image Extractor - Quick Test Guide

This guide shows how to quickly test the image_extractor pipeline with actual commands.

## Prerequisites

```bash
# Check Python version (requires 3.8+)
python3 --version
# Python 3.13.3

# Verify dependencies are installed
python3 -c "import cv2, numpy; print('Dependencies OK')"
# Dependencies OK
```

## Run Automated Test Suite

```bash
cd /Users/nishantgupta/Documents/nishant_projects/familycolorfun/scripts
python3 run_tests.py
```

**Expected Output:**
```
✓ Dependencies loaded (cv2, numpy)
======================================================================
IMAGE EXTRACTOR PIPELINE - END-TO-END TEST SUITE
======================================================================
[... test execution ...]
======================================================================
TEST SUMMARY
======================================================================
✓ PASS: Single Image Processing
✓ PASS: Batch Processing
✓ PASS: Manifest Generation
✓ PASS: QA Validation

======================================================================
OVERALL: 4/4 tests passed
======================================================================
```

## Manual CLI Testing

### 1. Process Single Image

```bash
python3 -m image_extractor process \
  "/Users/nishantgupta/Documents/nishant_projects/familycolorfun/FamilyColorFun/Assets.xcassets/ColoringPages/house_cottage.imageset/house_cottage.png" \
  -o test_output \
  -p my_test_page \
  --debug
```

**Output:**
```
[my_test_page] Extracting lines...
[my_test_page] Extracting regions...
[my_test_page] Found 16 fillable regions
[my_test_page] Auto-classified as kids
[my_test_page] QA Result: pass
[my_test_page] Saving outputs...
[my_test_page] Complete!

Output saved to: test_output/my_test_page
```

**Generated Files:**
```
test_output/my_test_page/
├── image.png          (2048x2048 line art)
├── labels.png         (2048x2048 RGB label map)
├── thumb.png          (256x256 thumbnail)
├── metadata.json      (region data)
└── _debug/
    ├── my_test_page_debug_lines.png
    ├── my_test_page_debug_fillable.png
    ├── my_test_page_regions_preview.png
    └── my_test_page_thumb_regions.png
```

### 2. Process Batch

```bash
# Create test directory with images
mkdir -p batch_input
cp "/path/to/image1.png" batch_input/
cp "/path/to/image2.png" batch_input/

# Process batch
python3 -m image_extractor batch batch_input/ -o batch_output/
```

**Output:**
```
Found 2 images to process

[1/2] Processing: image1.png
[image1] Extracting lines...
[image1] Found 16 fillable regions
[image1] QA Result: pass
[image1] Complete!

[2/2] Processing: image2.png
[image2] Extracting lines...
[image2] Found 16 fillable regions
[image2] QA Result: pass
[image2] Complete!

==================================================
PROCESSING SUMMARY
==================================================
Total processed: 2
Success: 2
QA Pass: 2
QA Warn: 0
QA Fail: 0
Errors: 0
==================================================
```

### 3. Generate Manifest

```bash
python3 -m image_extractor manifest batch_output/ -o manifest.json
```

**Output:**
```
Manifest created: manifest.json
  Categories: 1
  Pages: 2
```

**Generated manifest.json structure:**
```json
{
  "version": "1.0.0",
  "generatedAt": "2025-12-13T04:20:52.960361+00:00",
  "categories": [...],
  "pages": [
    {
      "id": "image1",
      "assets": {
        "thumb": "image1/thumb.png",
        "image": "image1/image.png",
        "labels": "image1/labels.png",
        "metadata": "image1/metadata.json"
      },
      "checksums": {
        "thumb": "sha256:...",
        "image": "sha256:...",
        "labels": "sha256:...",
        "metadata": "sha256:..."
      }
    }
  ]
}
```

### 4. Validate QA

```bash
# Validate for kids age group
python3 -m image_extractor validate test_output/my_test_page -a kids
```

**Output:**
```
QA Result: PASS
Age Group: kids
Region Count: 16
Tiny Regions: 2 (12.5%)
```

```bash
# Validate for family age group
python3 -m image_extractor validate test_output/my_test_page -a family
```

**Output:**
```
QA Result: WARN
Age Group: family
Region Count: 16
Tiny Regions: 2 (12.5%)
Recommended Age Group: kids

Issues:
  [warn] AGE_GROUP_MISMATCH: Page may be better suited for kids age group
         Based on region count (16) and complexity
```

## Test Scenarios Covered

### ✓ Test 1: Single Image Processing
- **Status:** PASS
- **Input:** house_cottage.png
- **Output:** 4 files (image.png, labels.png, thumb.png, metadata.json)
- **Regions:** 16 detected
- **QA Result:** pass

### ✓ Test 2: Batch Processing
- **Status:** PASS
- **Images:** 2
- **Success Rate:** 100%
- **Output:** 2 complete page directories

### ✓ Test 3: Manifest Generation
- **Status:** PASS
- **Pages:** 2
- **Checksums:** SHA-256 for all assets
- **Categories:** 1

### ✓ Test 4: QA Validation
- **Status:** PASS
- **Age Groups Tested:** kids, family, adult
- **Results:** Appropriate PASS/WARN for each group

## Verify Output Files

```bash
# Check generated files
ls -lh test_output/my_test_page/

# Expected output:
# -rw-r--r--  29K image.png
# -rw-r--r--  36K labels.png
# -rw-r--r-- 4.1K thumb.png
# -rw-r--r-- 4.4K metadata.json

# Check image dimensions
python3 -c "import cv2; img = cv2.imread('test_output/my_test_page/image.png'); print(f'Dimensions: {img.shape}')"
# Dimensions: (2048, 2048, 3)

# Verify metadata structure
python3 -c "import json; m = json.load(open('test_output/my_test_page/metadata.json')); print(f'Regions: {m[\"totalRegions\"]}, Age: {m[\"ageGroup\"]}')"
# Regions: 16, Age: kids
```

## Common Options

### Process Command Options
- `-p, --page-id`: Custom page identifier (default: filename)
- `-a, --age-group`: Override age group (kids|family|adult)
- `-r, --resolution`: Output resolution (default: 2048)
- `--force`: Save output even if QA fails
- `--debug`: Generate debug visualization files

### Batch Command Options
- Same as process command
- Automatically skips files with "_labels", "_debug", "_thumb" in name

### Manifest Command Options
- `--base-url`: CDN base URL (default: https://cdn.familycolorfun.app/v1)
- `-o, --output`: Output file path (default: manifest.json)

### Validate Command Options
- `-a, --age-group`: Age group to validate against

## Exit Codes
- `0`: Success
- `1`: Failure (processing error or QA fail without --force)

## Tips

1. **Use debug mode** during development:
   ```bash
   python3 -m image_extractor process input.png -o output/ --debug
   ```

2. **Force output** for testing QA-failed pages:
   ```bash
   python3 -m image_extractor process input.png -o output/ --force
   ```

3. **Override age group** for specific targeting:
   ```bash
   python3 -m image_extractor process input.png -o output/ -a adult
   ```

4. **Test auto-classification** by not specifying age group:
   ```bash
   python3 -m image_extractor process input.png -o output/
   ```

## Troubleshooting

### Missing dependencies
```bash
pip install opencv-python numpy
```

### Permission errors
```bash
chmod +x run_tests.py
```

### Image not found
- Use absolute paths
- Verify file exists with: `ls -l /path/to/image.png`

## Test Results Summary

**Date:** 2025-12-12
**All Tests:** ✓ PASSED (4/4)
**Status:** Production Ready

See `TEST_REPORT.md` for detailed test results.
