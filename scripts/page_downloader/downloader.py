#!/usr/bin/env python3
"""
Main downloader script for acquiring free coloring pages.
Downloads from various sources and validates for coloring app use.
"""
import argparse
import json
import sys
from datetime import datetime
from pathlib import Path

# Add parent to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from page_downloader.config import (
    SEARCH_CATEGORIES,
    CATEGORY_TARGETS,
    RAW_DOWNLOADS_DIR,
    PIXABAY_API_KEY
)
from page_downloader.sources.pixabay import PixabaySource
from page_downloader.utils import get_image_info


def download_coloring_pages(
    categories: list = None,
    target_per_category: int = None,
    api_key: str = None
):
    """
    Download coloring pages from configured sources.

    Args:
        categories: List of categories to download (None = all)
        target_per_category: Override target count per category
        api_key: Pixabay API key (optional, uses env if not provided)
    """
    # Filter categories if specified
    if categories:
        search_terms = {k: v for k, v in SEARCH_CATEGORIES.items() if k in categories}
        targets = {k: v for k, v in CATEGORY_TARGETS.items() if k in categories}
    else:
        search_terms = SEARCH_CATEGORIES
        targets = CATEGORY_TARGETS

    # Override targets if specified
    if target_per_category:
        targets = {k: target_per_category for k in targets}

    # Use provided API key or env
    key = api_key or PIXABAY_API_KEY

    if not key:
        print("ERROR: Pixabay API key required!")
        print("Set PIXABAY_API_KEY environment variable or pass --api-key")
        print("Get free key at: https://pixabay.com/api/docs/")
        sys.exit(1)

    # Initialize downloader
    print("\n" + "=" * 60)
    print("COLORING PAGE DOWNLOADER")
    print("=" * 60)
    print(f"Categories: {', '.join(search_terms.keys())}")
    print(f"Targets: {sum(targets.values())} total images")
    print("=" * 60)

    try:
        source = PixabaySource(api_key=key)
    except ValueError as e:
        print(f"ERROR: {e}")
        sys.exit(1)

    # Download all
    results = source.download_all_categories(search_terms, targets)

    # Save manifest
    manifest_path = RAW_DOWNLOADS_DIR / "download_manifest.json"
    manifest = {
        "download_date": datetime.now().isoformat(),
        "source": "pixabay",
        "categories": {}
    }

    for category, downloads in results.items():
        manifest["categories"][category] = {
            "count": len(downloads),
            "files": [d["path"] for d in downloads]
        }

    with open(manifest_path, 'w') as f:
        json.dump(manifest, f, indent=2)

    print(f"Manifest saved to: {manifest_path}")

    return results


def list_downloads():
    """List all downloaded images."""
    print("\nDownloaded Coloring Pages:")
    print("-" * 40)

    total = 0
    for category_dir in RAW_DOWNLOADS_DIR.iterdir():
        if category_dir.is_dir():
            images = list(category_dir.glob("*.jpg")) + list(category_dir.glob("*.png"))
            count = len(images)
            total += count
            print(f"  {category_dir.name}: {count} images")

    print("-" * 40)
    print(f"  Total: {total} images")


def validate_downloads():
    """Validate all downloaded images."""
    print("\nValidating Downloads:")
    print("-" * 40)

    valid_count = 0
    invalid_count = 0

    for category_dir in RAW_DOWNLOADS_DIR.iterdir():
        if not category_dir.is_dir():
            continue

        images = list(category_dir.glob("*.jpg")) + list(category_dir.glob("*.png"))

        for img_path in images:
            info = get_image_info(img_path)
            if info.get("is_line_art"):
                valid_count += 1
            else:
                invalid_count += 1
                print(f"  Invalid: {img_path.name} - {info.get('validation_reason', 'unknown')}")

    print("-" * 40)
    print(f"  Valid: {valid_count}, Invalid: {invalid_count}")


def main():
    parser = argparse.ArgumentParser(
        description="Download free coloring pages for training"
    )

    subparsers = parser.add_subparsers(dest="command", help="Commands")

    # Download command
    download_parser = subparsers.add_parser("download", help="Download coloring pages")
    download_parser.add_argument(
        "--categories",
        nargs="+",
        choices=list(SEARCH_CATEGORIES.keys()),
        help="Categories to download (default: all)"
    )
    download_parser.add_argument(
        "--target",
        type=int,
        help="Target images per category"
    )
    download_parser.add_argument(
        "--api-key",
        help="Pixabay API key"
    )

    # List command
    subparsers.add_parser("list", help="List downloaded images")

    # Validate command
    subparsers.add_parser("validate", help="Validate downloaded images")

    args = parser.parse_args()

    if args.command == "download":
        download_coloring_pages(
            categories=args.categories,
            target_per_category=args.target,
            api_key=args.api_key
        )
    elif args.command == "list":
        list_downloads()
    elif args.command == "validate":
        validate_downloads()
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
