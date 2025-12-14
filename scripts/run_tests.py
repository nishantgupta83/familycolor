#!/usr/bin/env python3
"""
End-to-end test suite for image_extractor pipeline.
Tests all major functionality and reports PASS/FAIL status.
"""

import sys
import os
import json
import shutil
from pathlib import Path

# Add image_extractor to path
sys.path.insert(0, str(Path(__file__).parent))

# Test dependencies
try:
    import cv2
    import numpy as np
    print("✓ Dependencies loaded (cv2, numpy)")
except ImportError as e:
    print(f"✗ FAIL: Missing dependency - {e}")
    print("  Install with: pip install opencv-python numpy")
    sys.exit(1)

from image_extractor.config import Config, AgeGroup
from image_extractor.pipeline import Pipeline
from image_extractor.manifest_builder import ManifestBuilder
from image_extractor.qa_validator import QAValidator

# Test configuration
TEST_IMAGE = "/Users/nishantgupta/Documents/nishant_projects/familycolorfun/FamilyColorFun/Assets.xcassets/ColoringPages/house_cottage.imageset/house_cottage.png"
TEST_OUTPUT = Path(__file__).parent / "test_output"
BATCH_TEST_DIR = Path(__file__).parent / "test_batch_input"


def print_header(test_name):
    """Print test section header."""
    print("\n" + "=" * 70)
    print(f"TEST: {test_name}")
    print("=" * 70)


def verify_file_exists(filepath, description):
    """Verify a file exists and print result."""
    exists = filepath.exists()
    status = "✓ PASS" if exists else "✗ FAIL"
    print(f"{status}: {description} - {filepath.name}")
    return exists


def verify_metadata_fields(metadata_path):
    """Verify metadata.json has all required fields."""
    print("\nVerifying metadata.json structure...")

    with open(metadata_path) as f:
        metadata = json.load(f)

    required_fields = [
        "imageName",
        "imageSize",
        "totalRegions",
        "labelEncoding",
        "regions"
    ]

    all_present = True
    for field in required_fields:
        present = field in metadata
        status = "✓" if present else "✗"
        print(f"  {status} {field}: {metadata.get(field, 'MISSING')}")
        all_present = all_present and present

    # Verify region structure
    if metadata.get("regions"):
        first_region = metadata["regions"][0]
        region_fields = ["id", "centroid", "boundingBox", "pixelCount"]
        print("\n  Region structure:")
        for field in region_fields:
            present = field in first_region
            status = "✓" if present else "✗"
            print(f"    {status} {field}")
            all_present = all_present and present

    return all_present


def test_single_image_processing():
    """TEST 1: Single image processing."""
    print_header("1. Single Image Processing")

    # Clean output directory
    if TEST_OUTPUT.exists():
        shutil.rmtree(TEST_OUTPUT)
    TEST_OUTPUT.mkdir(parents=True)

    # Verify test image exists
    if not Path(TEST_IMAGE).exists():
        print(f"✗ FAIL: Test image not found: {TEST_IMAGE}")
        return False

    print(f"Input: {Path(TEST_IMAGE).name}")

    # Process image
    config = Config(debug_output=True)
    pipeline = Pipeline(config)

    result = pipeline.process_page(
        input_path=Path(TEST_IMAGE),
        page_id="house_cottage_test",
        output_dir=TEST_OUTPUT,
        skip_qa_fail=True  # Force output even if QA fails
    )

    if not result.success:
        print(f"✗ FAIL: Processing failed - {result.error}")
        return False

    print(f"✓ Processing completed")
    print(f"  Output dir: {result.output_dir}")
    print(f"  QA Result: {result.qa_report.result.value if result.qa_report else 'N/A'}")
    print(f"  Regions found: {len(result.metadata.get('regions', []))}")

    # Verify output files
    print("\nVerifying output files...")
    page_dir = result.output_dir

    checks = [
        verify_file_exists(page_dir / "image.png", "Line art image"),
        verify_file_exists(page_dir / "labels.png", "Label map"),
        verify_file_exists(page_dir / "thumb.png", "Thumbnail"),
        verify_file_exists(page_dir / "metadata.json", "Metadata JSON"),
    ]

    # Verify metadata structure
    if (page_dir / "metadata.json").exists():
        checks.append(verify_metadata_fields(page_dir / "metadata.json"))

    # Verify debug outputs
    debug_dir = page_dir / "_debug"
    if debug_dir.exists():
        print("\nDebug outputs:")
        for debug_file in debug_dir.glob("*.png"):
            print(f"  ✓ {debug_file.name}")

    overall = all(checks)
    print(f"\n{'✓ PASS' if overall else '✗ FAIL'}: Single image processing test")
    return overall


def test_batch_processing():
    """TEST 2: Batch processing."""
    print_header("2. Batch Processing")

    # Create test batch directory
    if BATCH_TEST_DIR.exists():
        shutil.rmtree(BATCH_TEST_DIR)
    BATCH_TEST_DIR.mkdir(parents=True)

    # Copy test images (use house_cottage multiple times with different names for testing)
    test_images = [
        ("house_cottage_1.png", TEST_IMAGE),
        ("house_cottage_2.png", TEST_IMAGE),
    ]

    print("Creating test batch...")
    for name, source in test_images:
        dest = BATCH_TEST_DIR / name
        shutil.copy(source, dest)
        print(f"  ✓ {name}")

    # Clean batch output
    batch_output = TEST_OUTPUT / "batch"
    if batch_output.exists():
        shutil.rmtree(batch_output)
    batch_output.mkdir(parents=True)

    # Process batch
    print("\nProcessing batch...")
    config = Config(debug_output=False)
    pipeline = Pipeline(config)

    results = pipeline.process_batch(
        input_dir=BATCH_TEST_DIR,
        output_dir=batch_output,
        skip_qa_fail=True
    )

    print(f"\nBatch results:")
    print(f"  Total images: {len(results)}")
    print(f"  Successful: {sum(1 for r in results if r.success)}")
    print(f"  Failed: {sum(1 for r in results if not r.success)}")

    # Verify each processed image
    all_success = True
    for result in results:
        if result.success:
            page_dir = result.output_dir
            has_files = all([
                (page_dir / "image.png").exists(),
                (page_dir / "labels.png").exists(),
                (page_dir / "thumb.png").exists(),
                (page_dir / "metadata.json").exists(),
            ])
            status = "✓" if has_files else "✗"
            print(f"  {status} {result.page_id}")
            all_success = all_success and has_files
        else:
            print(f"  ✗ {result.page_id} - {result.error}")
            all_success = False

    # Cleanup
    shutil.rmtree(BATCH_TEST_DIR)

    print(f"\n{'✓ PASS' if all_success else '✗ FAIL'}: Batch processing test")
    return all_success


def test_manifest_generation():
    """TEST 3: Manifest generation."""
    print_header("3. Manifest Generation")

    # Use the batch output from previous test
    batch_output = TEST_OUTPUT / "batch"

    if not batch_output.exists() or not any(batch_output.iterdir()):
        print("✗ FAIL: No processed pages found for manifest generation")
        print("  (Batch test must run successfully first)")
        return False

    # Generate manifest
    print("Generating manifest...")
    manifest_path = TEST_OUTPUT / "test_manifest.json"

    try:
        builder = ManifestBuilder.from_processed_directory(
            processed_dir=batch_output,
            base_url="https://cdn.test.app/v1"
        )

        builder.save(manifest_path)
        manifest = builder.build()

        print(f"✓ Manifest created: {manifest_path.name}")
        print(f"  Version: {manifest.get('version')}")
        print(f"  Categories: {len(manifest.get('categories', []))}")
        print(f"  Total pages: {manifest.get('pageCount')}")

        # Verify manifest structure
        print("\nVerifying manifest structure...")
        required_fields = ["version", "categories", "pageCount", "generatedAt"]
        all_present = True

        for field in required_fields:
            present = field in manifest
            status = "✓" if present else "✗"
            print(f"  {status} {field}")
            all_present = all_present and present

        # Check categories structure
        if manifest.get("categories"):
            print("\nCategory structure:")
            for cat in manifest["categories"]:
                print(f"  ✓ {cat.get('name', 'unnamed')}: {len(cat.get('pages', []))} pages")

                # Check first page structure
                if cat.get("pages"):
                    page = cat["pages"][0]
                    page_fields = ["id", "thumbnailUrl", "imageUrl", "labelsUrl", "metadataUrl"]
                    for field in page_fields:
                        present = field in page
                        if not present:
                            print(f"    ✗ Missing {field}")
                            all_present = False

        print(f"\n{'✓ PASS' if all_present else '✗ FAIL'}: Manifest generation test")
        return all_present

    except Exception as e:
        print(f"✗ FAIL: Manifest generation error - {e}")
        import traceback
        traceback.print_exc()
        return False


def test_qa_validation():
    """TEST 4: QA validation with different age groups."""
    print_header("4. QA Validation")

    # Use existing processed page
    page_dir = TEST_OUTPUT / "house_cottage_test"
    metadata_path = page_dir / "metadata.json"

    if not metadata_path.exists():
        print("✗ FAIL: No processed page found for QA testing")
        print("  (Single image test must run successfully first)")
        return False

    # Load metadata
    with open(metadata_path) as f:
        metadata = json.load(f)

    # Reconstruct regions
    from image_extractor.processors.region_extractor import RegionMetadata

    regions = []
    for r in metadata.get("regions", []):
        region = RegionMetadata(
            region_id=r["id"],
            centroid=(r["centroid"]["x"], r["centroid"]["y"]),
            bounding_box=(
                r["boundingBox"]["x"],
                r["boundingBox"]["y"],
                r["boundingBox"]["width"],
                r["boundingBox"]["height"]
            ),
            pixel_count=r["pixelCount"]
        )
        regions.append(region)

    print(f"Loaded {len(regions)} regions from metadata")

    # Test validation for each age group
    config = Config()
    validator = QAValidator(config)

    age_groups = [AgeGroup.KIDS, AgeGroup.FAMILY, AgeGroup.ADULT]
    results = {}

    print("\nValidating against different age groups:")
    for age_group in age_groups:
        report = validator.validate(regions, age_group)
        results[age_group] = report

        status = "✓ PASS" if report.passed else ("⚠ WARN" if report.result.value == "warn" else "✗ FAIL")
        print(f"\n  {status} {age_group.value.upper()}")
        print(f"    Result: {report.result.value}")
        print(f"    Total regions: {len(regions)}")

        if report.issues:
            print(f"    Issues found: {len(report.issues)}")
            for issue in report.issues[:3]:  # Show first 3 issues
                print(f"      - [{issue.severity.value}] {issue.message}")
        else:
            print(f"    No issues found")

    # Test auto-classification
    print("\n  Testing auto-classification:")
    auto_age_group, auto_report = validator.auto_classify(regions)
    print(f"    ✓ Auto-classified as: {auto_age_group.value}")
    print(f"    Confidence: {auto_report.result.value}")

    # All age groups should produce a result (not crash)
    all_tested = len(results) == len(age_groups)

    print(f"\n{'✓ PASS' if all_tested else '✗ FAIL'}: QA validation test")
    return all_tested


def main():
    """Run all tests and report summary."""
    print("=" * 70)
    print("IMAGE EXTRACTOR PIPELINE - END-TO-END TEST SUITE")
    print("=" * 70)

    # Run all tests
    test_results = {
        "Single Image Processing": test_single_image_processing(),
        "Batch Processing": test_batch_processing(),
        "Manifest Generation": test_manifest_generation(),
        "QA Validation": test_qa_validation(),
    }

    # Print summary
    print("\n" + "=" * 70)
    print("TEST SUMMARY")
    print("=" * 70)

    for test_name, passed in test_results.items():
        status = "✓ PASS" if passed else "✗ FAIL"
        print(f"{status}: {test_name}")

    total = len(test_results)
    passed = sum(1 for p in test_results.values() if p)

    print("\n" + "=" * 70)
    print(f"OVERALL: {passed}/{total} tests passed")
    print("=" * 70)

    return 0 if all(test_results.values()) else 1


if __name__ == "__main__":
    sys.exit(main())
