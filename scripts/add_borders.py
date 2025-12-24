#!/usr/bin/env python3
"""Add borders to coloring page images to prevent color bleeding.

This script processes coloring page images to:
1. Add a black border around the edges
2. Thicken lines to ensure proper fill boundaries
3. Convert to consistent grayscale format

Usage:
    python3 add_borders.py [--assets PATH] [--raw PATH] [--border-width N]

Requirements:
    - opencv-python
    - numpy
"""
import argparse
import logging
import sys
from pathlib import Path
from typing import Optional, Tuple

import cv2
import numpy as np

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(levelname)s: %(message)s'
)
logger = logging.getLogger(__name__)

# Default configuration
DEFAULT_BORDER_WIDTH = 3
DEFAULT_LINE_THICKNESS_KERNEL = 2


class ImageProcessingError(Exception):
    """Raised when image processing fails."""
    pass


class ImageReadError(ImageProcessingError):
    """Raised when reading an image fails."""
    pass


class ImageWriteError(ImageProcessingError):
    """Raised when writing an image fails."""
    pass


def load_image(image_path: Path) -> np.ndarray:
    """Load an image from disk.

    Args:
        image_path: Path to the image file

    Returns:
        Image as numpy array

    Raises:
        ImageReadError: If the image cannot be read
    """
    if not image_path.exists():
        raise ImageReadError(f"File not found: {image_path}")

    try:
        img = cv2.imread(str(image_path), cv2.IMREAD_UNCHANGED)
        if img is None:
            raise ImageReadError(f"cv2.imread returned None for {image_path}")
        return img
    except cv2.error as e:
        raise ImageReadError(f"OpenCV error reading {image_path}: {e}") from e


def save_image(img: np.ndarray, output_path: Path) -> None:
    """Save an image to disk.

    Args:
        img: Image to save
        output_path: Destination path

    Raises:
        ImageWriteError: If the image cannot be saved
    """
    try:
        # Ensure parent directory exists
        output_path.parent.mkdir(parents=True, exist_ok=True)
        success = cv2.imwrite(str(output_path), img)
        if not success:
            raise ImageWriteError(f"cv2.imwrite returned False for {output_path}")
    except cv2.error as e:
        raise ImageWriteError(f"OpenCV error writing {output_path}: {e}") from e
    except OSError as e:
        raise ImageWriteError(f"OS error writing {output_path}: {e}") from e


def convert_to_grayscale(img: np.ndarray) -> np.ndarray:
    """Convert an image to grayscale.

    Args:
        img: Input image (can be grayscale, BGR, or BGRA)

    Returns:
        Grayscale image

    Raises:
        ImageProcessingError: If the image format is unsupported
    """
    if len(img.shape) == 2:
        # Already grayscale
        return img

    if len(img.shape) != 3:
        raise ImageProcessingError(f"Unexpected image dimensions: {img.shape}")

    channels = img.shape[2]
    if channels == 4:
        # BGRA - extract BGR and convert
        bgr = img[:, :, :3]
        return cv2.cvtColor(bgr, cv2.COLOR_BGR2GRAY)
    elif channels == 3:
        # BGR
        return cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    else:
        raise ImageProcessingError(f"Unexpected channel count: {channels}")


def add_border_to_image(
    image_path: Path,
    border_width: int = DEFAULT_BORDER_WIDTH,
    output_path: Optional[Path] = None
) -> bool:
    """Add a black border around the image to prevent color bleeding.

    Args:
        image_path: Path to the input image
        border_width: Width of the border in pixels
        output_path: Optional output path (defaults to overwriting input)

    Returns:
        True if successful, False otherwise
    """
    if output_path is None:
        output_path = image_path

    try:
        # Load image
        img = load_image(image_path)
        height, width = img.shape[:2]

        # Convert to grayscale
        gray = convert_to_grayscale(img)

        # Create a binary mask of the lines (black lines on white background)
        _, line_mask = cv2.threshold(gray, 200, 255, cv2.THRESH_BINARY_INV)

        # Dilate lines slightly to ensure they're thick enough (minimum 2-3px)
        kernel = np.ones((DEFAULT_LINE_THICKNESS_KERNEL, DEFAULT_LINE_THICKNESS_KERNEL), np.uint8)
        thickened_lines = cv2.dilate(line_mask, kernel, iterations=1)

        # Add outer border
        border_mask = np.zeros_like(thickened_lines)
        border_mask[:border_width, :] = 255  # Top
        border_mask[-border_width:, :] = 255  # Bottom
        border_mask[:, :border_width] = 255  # Left
        border_mask[:, -border_width:] = 255  # Right

        # Combine lines with border
        combined_mask = cv2.bitwise_or(thickened_lines, border_mask)

        # Create output image (white background with black lines)
        output = np.ones((height, width, 3), dtype=np.uint8) * 255
        output[combined_mask > 0] = [0, 0, 0]

        # Save
        save_image(output, output_path)
        return True

    except ImageReadError as e:
        logger.error(f"Read error: {e}")
        return False
    except ImageWriteError as e:
        logger.error(f"Write error: {e}")
        return False
    except ImageProcessingError as e:
        logger.error(f"Processing error: {e}")
        return False


def process_coloring_pages(assets_dir: Path, border_width: int) -> Tuple[int, int, int]:
    """Process all coloring pages in the assets directory.

    Args:
        assets_dir: Path to Assets.xcassets folder
        border_width: Border width in pixels

    Returns:
        Tuple of (processed, skipped, errors) counts
    """
    coloring_pages_dir = assets_dir / "ColoringPages"

    if not coloring_pages_dir.exists():
        logger.error(f"ColoringPages directory not found: {coloring_pages_dir}")
        return 0, 0, 0

    # Find all imagesets
    imagesets = list(coloring_pages_dir.glob("*.imageset"))
    logger.info(f"Found {len(imagesets)} imagesets")

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
            logger.debug(f"No images in {imageset.name}")
            skipped += 1
            continue

        for image_file in image_files:
            logger.info(f"Processing: {image_file.name}")
            if add_border_to_image(image_file, border_width):
                processed += 1
            else:
                errors += 1

    return processed, skipped, errors


def process_raw_downloads(raw_dir: Path, border_width: int) -> Tuple[int, int]:
    """Process images in raw_downloads folders.

    Args:
        raw_dir: Path to raw downloads folder
        border_width: Border width in pixels

    Returns:
        Tuple of (processed, errors) counts
    """
    processed = 0
    errors = 0

    # Process standard subdirectories
    for subdir in ["generated", "new_categories", "improved_animals"]:
        dir_path = raw_dir / subdir
        if not dir_path.exists():
            continue

        images = list(dir_path.glob("*.png"))
        if not images:
            continue

        logger.info(f"\nProcessing {len(images)} images in {subdir}/")

        for img_path in images:
            logger.info(f"  Adding border to: {img_path.name}")
            if add_border_to_image(img_path, border_width):
                processed += 1
            else:
                errors += 1

    # Also process if raw_dir itself contains images (when --raw points to a specific folder)
    direct_images = list(raw_dir.glob("*.png"))
    if direct_images:
        logger.info(f"\nProcessing {len(direct_images)} images in {raw_dir.name}/")
        for img_path in direct_images:
            logger.info(f"  Adding border to: {img_path.name}")
            if add_border_to_image(img_path, border_width):
                processed += 1
            else:
                errors += 1

    return processed, errors


def parse_args() -> argparse.Namespace:
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(
        description="Add borders to coloring pages to prevent color bleeding",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument(
        "--assets",
        type=Path,
        help="Path to Assets.xcassets folder"
    )
    parser.add_argument(
        "--raw",
        type=Path,
        help="Path to raw_downloads folder or specific image folder"
    )
    parser.add_argument(
        "--border-width",
        type=int,
        default=DEFAULT_BORDER_WIDTH,
        help="Border width in pixels"
    )
    parser.add_argument(
        "--verbose", "-v",
        action="store_true",
        help="Enable verbose output"
    )
    return parser.parse_args()


def main() -> int:
    """Main entry point.

    Returns:
        Exit code (0 for success, non-zero for errors)
    """
    args = parse_args()

    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)

    # Default paths
    script_dir = Path(__file__).parent
    project_dir = script_dir.parent

    assets_dir = args.assets or (project_dir / "FamilyColorFun" / "Assets.xcassets")
    raw_dir = args.raw or (script_dir / "raw_downloads")

    print("=" * 50)
    print("Adding Borders to Coloring Pages")
    print("=" * 50)
    print(f"Border width: {args.border_width}px")

    total_processed = 0
    total_errors = 0

    # Process Assets.xcassets
    if assets_dir.exists():
        logger.info(f"\nProcessing Assets: {assets_dir}")
        processed, skipped, errors = process_coloring_pages(assets_dir, args.border_width)
        total_processed += processed
        total_errors += errors
        print(f"\nSummary:")
        print(f"  Processed: {processed}")
        print(f"  Skipped: {skipped}")
        print(f"  Errors: {errors}")

    # Process raw downloads
    if raw_dir.exists():
        logger.info(f"\nProcessing Raw Downloads: {raw_dir}")
        processed, errors = process_raw_downloads(raw_dir, args.border_width)
        total_processed += processed
        total_errors += errors

    print("\nDone!")
    return 0 if total_errors == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
