#!/usr/bin/env python3
"""
Add borders to coloring page images to prevent color bleeding.
Processes all images in the ColoringPages assets folder.
"""
import cv2
import numpy as np
from pathlib import Path


def add_border_to_image(image_path: Path, border_width: int = 3, output_path: Path = None) -> bool:
    """
    Add a black border around the image to prevent color bleeding.
    Also ensures the image has proper line thickness.
    """
    if output_path is None:
        output_path = image_path

    try:
        # Read image
        img = cv2.imread(str(image_path), cv2.IMREAD_UNCHANGED)
        if img is None:
            print(f"  Could not read: {image_path}")
            return False

        height, width = img.shape[:2]

        # Handle different image formats
        if len(img.shape) == 2:
            # Already grayscale
            gray = img
        elif len(img.shape) == 3:
            if img.shape[2] == 4:
                # RGBA - convert BGR part to grayscale
                bgr = img[:, :, :3]
                gray = cv2.cvtColor(bgr, cv2.COLOR_BGR2GRAY)
            elif img.shape[2] == 3:
                # BGR
                gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
            else:
                print(f"  Unexpected channel count: {img.shape[2]}")
                return False
        else:
            print(f"  Unexpected image shape: {img.shape}")
            return False

        # Create a binary mask of the lines (black lines on white background)
        # Threshold to get line mask
        _, line_mask = cv2.threshold(gray, 200, 255, cv2.THRESH_BINARY_INV)

        # Dilate lines slightly to ensure they're thick enough (minimum 2-3px)
        kernel = np.ones((2, 2), np.uint8)
        thickened_lines = cv2.dilate(line_mask, kernel, iterations=1)

        # Add outer border
        border_mask = np.zeros_like(thickened_lines)
        # Top border
        border_mask[:border_width, :] = 255
        # Bottom border
        border_mask[-border_width:, :] = 255
        # Left border
        border_mask[:, :border_width] = 255
        # Right border
        border_mask[:, -border_width:] = 255

        # Combine lines with border
        combined_mask = cv2.bitwise_or(thickened_lines, border_mask)

        # Create output image (white background with black lines)
        output = np.ones((height, width, 3), dtype=np.uint8) * 255

        # Apply lines
        output[combined_mask > 0] = [0, 0, 0]

        # Save
        cv2.imwrite(str(output_path), output)
        return True

    except Exception as e:
        print(f"  Error processing {image_path}: {e}")
        return False


def process_coloring_pages(assets_dir: Path, border_width: int = 3):
    """Process all coloring pages in the assets directory."""
    coloring_pages_dir = assets_dir / "ColoringPages"

    if not coloring_pages_dir.exists():
        print(f"ColoringPages directory not found: {coloring_pages_dir}")
        return

    # Find all imagesets
    imagesets = list(coloring_pages_dir.glob("*.imageset"))
    print(f"Found {len(imagesets)} imagesets")

    processed = 0
    skipped = 0
    errors = 0

    for imageset in imagesets:
        # Skip labels imagesets
        if "_labels" in imageset.name:
            continue

        # Find the actual image file
        image_files = list(imageset.glob("*.png")) + list(imageset.glob("*.jpg"))

        if not image_files:
            print(f"  No images in {imageset.name}")
            skipped += 1
            continue

        for image_file in image_files:
            print(f"Processing: {image_file.name}")
            if add_border_to_image(image_file, border_width):
                processed += 1
            else:
                errors += 1

    print(f"\nSummary:")
    print(f"  Processed: {processed}")
    print(f"  Skipped: {skipped}")
    print(f"  Errors: {errors}")


def process_raw_downloads(raw_dir: Path, border_width: int = 3):
    """Process images in raw_downloads folders."""
    for subdir in ["generated", "new_categories"]:
        dir_path = raw_dir / subdir
        if not dir_path.exists():
            continue

        images = list(dir_path.glob("*.png"))
        print(f"\nProcessing {len(images)} images in {subdir}/")

        for img_path in images:
            print(f"  Adding border to: {img_path.name}")
            add_border_to_image(img_path, border_width)


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Add borders to coloring pages")
    parser.add_argument("--assets", type=str, help="Path to Assets.xcassets folder")
    parser.add_argument("--raw", type=str, help="Path to raw_downloads folder")
    parser.add_argument("--border-width", type=int, default=3, help="Border width in pixels")

    args = parser.parse_args()

    # Default paths
    script_dir = Path(__file__).parent
    project_dir = script_dir.parent

    if args.assets:
        assets_dir = Path(args.assets)
    else:
        assets_dir = project_dir / "FamilyColorFun" / "Assets.xcassets"

    if args.raw:
        raw_dir = Path(args.raw)
    else:
        raw_dir = script_dir / "raw_downloads"

    print("=" * 50)
    print("Adding Borders to Coloring Pages")
    print("=" * 50)
    print(f"Border width: {args.border_width}px")

    # Process Assets.xcassets
    if assets_dir.exists():
        print(f"\nProcessing Assets: {assets_dir}")
        process_coloring_pages(assets_dir, args.border_width)

    # Process raw downloads
    if raw_dir.exists():
        print(f"\nProcessing Raw Downloads: {raw_dir}")
        process_raw_downloads(raw_dir, args.border_width)

    print("\nDone!")


if __name__ == "__main__":
    main()
