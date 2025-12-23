"""
Utility functions for image validation and processing.
"""
import hashlib
from pathlib import Path
from typing import Optional, Tuple
import cv2
import numpy as np
from PIL import Image

from .config import (
    MIN_IMAGE_WIDTH,
    MIN_IMAGE_HEIGHT,
    MAX_COLOR_VARIANCE,
    MIN_WHITE_PERCENTAGE,
    MAX_BLACK_PERCENTAGE
)


def validate_image_size(image_path: Path) -> bool:
    """Check if image meets minimum size requirements."""
    try:
        with Image.open(image_path) as img:
            width, height = img.size
            return width >= MIN_IMAGE_WIDTH and height >= MIN_IMAGE_HEIGHT
    except Exception as e:
        print(f"Error checking image size: {e}")
        return False


def is_line_art(image_path: Path) -> Tuple[bool, str]:
    """
    Detect if image is suitable line art for coloring.
    Returns (is_valid, reason).
    """
    try:
        img = cv2.imread(str(image_path))
        if img is None:
            return False, "Could not read image"

        # Convert to grayscale
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

        # Calculate color statistics
        total_pixels = gray.size
        white_pixels = np.sum(gray > 240)
        black_pixels = np.sum(gray < 30)
        mid_pixels = total_pixels - white_pixels - black_pixels

        white_pct = white_pixels / total_pixels
        black_pct = black_pixels / total_pixels

        # Check white background percentage
        if white_pct < MIN_WHITE_PERCENTAGE:
            return False, f"Not enough white background ({white_pct:.1%} < {MIN_WHITE_PERCENTAGE:.0%})"

        # Check black line percentage (too much = filled image)
        if black_pct > MAX_BLACK_PERCENTAGE:
            return False, f"Too much black ({black_pct:.1%} > {MAX_BLACK_PERCENTAGE:.0%})"

        # Check color variance (should be mostly black and white)
        std_dev = np.std(gray)
        if std_dev > MAX_COLOR_VARIANCE * 2:  # Allow some gradient
            pass  # Still might be valid

        # Check for distinct lines using edge detection
        edges = cv2.Canny(gray, 50, 150)
        edge_density = np.sum(edges > 0) / total_pixels

        if edge_density < 0.01:
            return False, "Too few lines/edges detected"

        if edge_density > 0.3:
            return False, "Too many edges (possibly photograph)"

        return True, "Valid line art"

    except Exception as e:
        return False, f"Validation error: {e}"


def calculate_image_hash(image_path: Path) -> str:
    """Calculate perceptual hash for deduplication."""
    try:
        img = cv2.imread(str(image_path), cv2.IMREAD_GRAYSCALE)
        if img is None:
            return ""

        # Resize to 8x8
        resized = cv2.resize(img, (8, 8), interpolation=cv2.INTER_AREA)

        # Calculate average
        avg = resized.mean()

        # Create hash based on whether each pixel is above average
        bits = resized > avg
        hash_value = 0
        for bit in bits.flatten():
            hash_value = (hash_value << 1) | int(bit)

        return format(hash_value, '016x')

    except Exception as e:
        print(f"Error calculating hash: {e}")
        return hashlib.md5(image_path.read_bytes()).hexdigest()[:16]


def is_duplicate(image_path: Path, existing_hashes: set) -> bool:
    """Check if image is a duplicate based on perceptual hash."""
    img_hash = calculate_image_hash(image_path)
    if img_hash in existing_hashes:
        return True
    existing_hashes.add(img_hash)
    return False


def convert_to_grayscale_png(image_path: Path, output_path: Optional[Path] = None) -> Path:
    """Convert image to grayscale PNG format."""
    if output_path is None:
        output_path = image_path.with_suffix('.png')

    try:
        img = cv2.imread(str(image_path))
        if img is None:
            raise ValueError(f"Could not read image: {image_path}")

        # Convert to grayscale
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

        # Enhance contrast for line art
        gray = cv2.convertScaleAbs(gray, alpha=1.2, beta=10)

        # Save as PNG
        cv2.imwrite(str(output_path), gray)

        return output_path

    except Exception as e:
        print(f"Error converting image: {e}")
        return image_path


def get_image_info(image_path: Path) -> dict:
    """Get detailed image information."""
    try:
        with Image.open(image_path) as img:
            info = {
                "path": str(image_path),
                "width": img.width,
                "height": img.height,
                "format": img.format,
                "mode": img.mode,
                "file_size_kb": image_path.stat().st_size // 1024
            }

        # Add line art analysis
        is_valid, reason = is_line_art(image_path)
        info["is_line_art"] = is_valid
        info["validation_reason"] = reason
        info["hash"] = calculate_image_hash(image_path)

        return info

    except Exception as e:
        return {"path": str(image_path), "error": str(e)}


def cleanup_filename(name: str) -> str:
    """Clean up filename for safe storage."""
    # Remove special characters
    clean = "".join(c if c.isalnum() or c in "._- " else "_" for c in name)
    # Replace spaces with underscores
    clean = clean.replace(" ", "_")
    # Remove multiple underscores
    while "__" in clean:
        clean = clean.replace("__", "_")
    # Limit length
    return clean[:100].strip("_")
