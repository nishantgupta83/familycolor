#!/usr/bin/env python3
"""
Command-line interface for the image extraction pipeline.

Usage:
    # Process single image
    python -m image_extractor process input.png -o processed/ -p my_page_01

    # Process directory
    python -m image_extractor batch input_dir/ -o processed/

    # Build manifest
    python -m image_extractor manifest processed/ -o manifest.json

    # Validate existing page
    python -m image_extractor validate processed/my_page_01/
"""

import argparse
import sys
from pathlib import Path

from .config import Config, AgeGroup
from .pipeline import Pipeline
from .manifest_builder import ManifestBuilder


def cmd_process(args):
    """Process a single image."""
    config = Config(
        target_resolution=args.resolution,
        debug_output=args.debug,
    )
    pipeline = Pipeline(config)

    age_group = None
    if args.age_group:
        age_group = AgeGroup(args.age_group)

    result = pipeline.process_page(
        input_path=Path(args.input),
        page_id=args.page_id or Path(args.input).stem,
        output_dir=Path(args.output),
        age_group=age_group,
        skip_qa_fail=args.force,
    )

    if result.success:
        print(f"\nOutput saved to: {result.output_dir}")
        if result.qa_report:
            print(f"QA Result: {result.qa_report.result.value}")
            if result.qa_report.issues:
                print("\nQA Issues:")
                for issue in result.qa_report.issues:
                    print(f"  [{issue.severity.value}] {issue.message}")
        return 0
    else:
        print(f"\nProcessing failed: {result.error}")
        if result.qa_report:
            print(result.qa_report.summary())
        return 1


def cmd_batch(args):
    """Process all images in a directory."""
    config = Config(
        target_resolution=args.resolution,
        debug_output=args.debug,
    )
    pipeline = Pipeline(config)

    age_group = None
    if args.age_group:
        age_group = AgeGroup(args.age_group)

    results = pipeline.process_batch(
        input_dir=Path(args.input),
        output_dir=Path(args.output),
        age_group=age_group,
        skip_qa_fail=args.force,
    )

    success_count = sum(1 for r in results if r.success)
    return 0 if success_count == len(results) else 1


def cmd_manifest(args):
    """Build manifest from processed directory."""
    processed_dir = Path(args.input)

    builder = ManifestBuilder.from_processed_directory(
        processed_dir=processed_dir,
        base_url=args.base_url,
    )

    output_path = Path(args.output)
    builder.save(output_path)

    manifest = builder.build()
    print(f"Manifest created: {output_path}")
    print(f"  Categories: {len(manifest['categories'])}")
    print(f"  Pages: {manifest['pageCount']}")

    return 0


def cmd_validate(args):
    """Validate an existing processed page."""
    import json
    from .qa_validator import QAValidator
    from .processors.region_extractor import RegionMetadata

    page_dir = Path(args.input)
    metadata_path = page_dir / "metadata.json"

    if not metadata_path.exists():
        print(f"Error: metadata.json not found in {page_dir}")
        return 1

    with open(metadata_path) as f:
        metadata = json.load(f)

    # Reconstruct regions from metadata
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

    # Determine age group
    if args.age_group:
        age_group = AgeGroup(args.age_group)
    elif "ageGroup" in metadata:
        age_group = AgeGroup(metadata["ageGroup"])
    else:
        age_group = AgeGroup.FAMILY

    config = Config()
    validator = QAValidator(config)
    report = validator.validate(regions, age_group)

    print(report.summary())
    return 0 if report.passed else 1


def main():
    parser = argparse.ArgumentParser(
        description="FamilyColorFun Image Extraction Pipeline"
    )
    subparsers = parser.add_subparsers(dest="command", help="Command to run")

    # Process command
    process_parser = subparsers.add_parser(
        "process",
        help="Process a single image"
    )
    process_parser.add_argument("input", help="Input image path")
    process_parser.add_argument("-o", "--output", required=True, help="Output directory")
    process_parser.add_argument("-p", "--page-id", help="Page ID (default: filename)")
    process_parser.add_argument(
        "-a", "--age-group",
        choices=["kids", "family", "adult"],
        help="Target age group (auto-detect if not specified)"
    )
    process_parser.add_argument(
        "-r", "--resolution",
        type=int,
        default=2048,
        help="Output resolution (default: 2048)"
    )
    process_parser.add_argument(
        "--force",
        action="store_true",
        help="Save output even if QA fails"
    )
    process_parser.add_argument(
        "--debug",
        action="store_true",
        help="Generate debug outputs"
    )
    process_parser.set_defaults(func=cmd_process)

    # Batch command
    batch_parser = subparsers.add_parser(
        "batch",
        help="Process all images in a directory"
    )
    batch_parser.add_argument("input", help="Input directory")
    batch_parser.add_argument("-o", "--output", required=True, help="Output directory")
    batch_parser.add_argument(
        "-a", "--age-group",
        choices=["kids", "family", "adult"],
        help="Target age group for all pages (auto-detect if not specified)"
    )
    batch_parser.add_argument(
        "-r", "--resolution",
        type=int,
        default=2048,
        help="Output resolution (default: 2048)"
    )
    batch_parser.add_argument(
        "--force",
        action="store_true",
        help="Save output even if QA fails"
    )
    batch_parser.add_argument(
        "--debug",
        action="store_true",
        help="Generate debug outputs"
    )
    batch_parser.set_defaults(func=cmd_batch)

    # Manifest command
    manifest_parser = subparsers.add_parser(
        "manifest",
        help="Build CDN manifest from processed pages"
    )
    manifest_parser.add_argument("input", help="Processed pages directory")
    manifest_parser.add_argument(
        "-o", "--output",
        default="manifest.json",
        help="Output manifest path (default: manifest.json)"
    )
    manifest_parser.add_argument(
        "--base-url",
        default="https://cdn.familycolorfun.app/v1",
        help="CDN base URL"
    )
    manifest_parser.set_defaults(func=cmd_manifest)

    # Validate command
    validate_parser = subparsers.add_parser(
        "validate",
        help="Validate an existing processed page"
    )
    validate_parser.add_argument("input", help="Processed page directory")
    validate_parser.add_argument(
        "-a", "--age-group",
        choices=["kids", "family", "adult"],
        help="Age group to validate against"
    )
    validate_parser.set_defaults(func=cmd_validate)

    # Parse and execute
    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        return 1

    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
