"""
Line extraction from scanned/photographed coloring pages.

Handles:
- Adaptive thresholding for uneven lighting
- Denoising
- Morphological operations to seal small gaps
- Resize to target resolution (2048x2048)
"""

import cv2
import numpy as np
from pathlib import Path
from typing import Tuple, Optional

from ..config import Config


class LineExtractor:
    """Extract clean line art from scanned coloring book pages."""

    def __init__(self, config: Config):
        self.config = config

    def extract(self, image_path: Path) -> Tuple[np.ndarray, np.ndarray]:
        """
        Extract clean line art from input image.

        Returns:
            Tuple of (line_art, fillable_mask) both at target resolution
            - line_art: Clean black lines on white background
            - fillable_mask: Binary mask of fillable interior regions
        """
        img = cv2.imread(str(image_path), cv2.IMREAD_GRAYSCALE)
        if img is None:
            raise ValueError(f"Could not read image: {image_path}")

        # Step 1: Resize to target resolution (maintaining aspect ratio, pad to square)
        img = self._resize_to_square(img, self.config.target_resolution)

        # Step 2: Adaptive thresholding (handles uneven lighting from photos)
        lines = self._extract_lines(img)

        # Step 3: Denoise
        lines = self._denoise(lines)

        # Step 4: Morphological close to seal small gaps
        lines_closed = self._close_gaps(lines)

        # Step 5: Create fillable mask (invert lines, remove exterior)
        fillable = self._create_fillable_mask(lines_closed)

        # Step 6: Create clean line art (white bg, black lines)
        line_art = cv2.bitwise_not(lines_closed)

        return line_art, fillable

    def _resize_to_square(self, img: np.ndarray, target_size: int) -> np.ndarray:
        """Resize image to square, maintaining aspect ratio with white padding."""
        h, w = img.shape[:2]

        # Calculate scale to fit within target
        scale = target_size / max(h, w)
        new_w = int(w * scale)
        new_h = int(h * scale)

        # Resize
        resized = cv2.resize(img, (new_w, new_h), interpolation=cv2.INTER_AREA)

        # Create white square canvas
        canvas = np.full((target_size, target_size), 255, dtype=np.uint8)

        # Center the resized image
        x_offset = (target_size - new_w) // 2
        y_offset = (target_size - new_h) // 2
        canvas[y_offset:y_offset + new_h, x_offset:x_offset + new_w] = resized

        return canvas

    def _extract_lines(self, img: np.ndarray) -> np.ndarray:
        """Extract black lines using adaptive thresholding."""
        # For scanned documents, adaptive threshold handles lighting variation
        # For clean digital images, simple threshold works fine

        # Try to detect if image is already clean (high contrast)
        hist = cv2.calcHist([img], [0], None, [256], [0, 256])
        peak_white = np.sum(hist[200:])
        peak_black = np.sum(hist[:50])

        if peak_white > img.size * 0.5 and peak_black > img.size * 0.01:
            # Already clean line art - use simple threshold
            _, lines = cv2.threshold(img, self.config.line_threshold, 255, cv2.THRESH_BINARY_INV)
        else:
            # Photo/scan - use adaptive threshold
            lines = cv2.adaptiveThreshold(
                img, 255,
                cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
                cv2.THRESH_BINARY_INV,
                blockSize=21,  # Must be odd
                C=10
            )

        return lines

    def _denoise(self, lines: np.ndarray) -> np.ndarray:
        """Remove small noise while preserving line structure."""
        # Morphological opening removes small white noise
        kernel = np.ones((2, 2), np.uint8)
        denoised = cv2.morphologyEx(lines, cv2.MORPH_OPEN, kernel, iterations=1)
        return denoised

    def _close_gaps(self, lines: np.ndarray) -> np.ndarray:
        """Seal small gaps in lines using morphological close."""
        kernel = np.ones(
            (self.config.morph_kernel_size, self.config.morph_kernel_size),
            np.uint8
        )
        closed = cv2.morphologyEx(
            lines,
            cv2.MORPH_CLOSE,
            kernel,
            iterations=self.config.morph_iterations
        )
        return closed

    def _create_fillable_mask(self, lines: np.ndarray) -> np.ndarray:
        """
        Create mask of interior fillable regions.
        Inverts lines and removes exterior background via flood fill.
        """
        h, w = lines.shape

        # Invert: white lines become white fillable areas
        fillable = cv2.bitwise_not(lines)

        # Flood fill from corners to remove exterior background
        mask = np.zeros((h + 2, w + 2), np.uint8)
        cv2.floodFill(fillable, mask, (0, 0), 0)
        cv2.floodFill(fillable, mask, (w - 1, 0), 0)
        cv2.floodFill(fillable, mask, (0, h - 1), 0)
        cv2.floodFill(fillable, mask, (w - 1, h - 1), 0)

        # Also try middle of edges in case corners are inside a region
        cv2.floodFill(fillable, mask, (w // 2, 0), 0)
        cv2.floodFill(fillable, mask, (w // 2, h - 1), 0)
        cv2.floodFill(fillable, mask, (0, h // 2), 0)
        cv2.floodFill(fillable, mask, (w - 1, h // 2), 0)

        # Force clean binary
        fillable = (fillable > 0).astype(np.uint8) * 255

        return fillable

    def save_debug_images(
        self,
        output_dir: Path,
        page_id: str,
        line_art: np.ndarray,
        fillable: np.ndarray
    ):
        """Save debug images for QA review."""
        output_dir.mkdir(parents=True, exist_ok=True)

        cv2.imwrite(str(output_dir / f"{page_id}_debug_lines.png"), line_art)
        cv2.imwrite(str(output_dir / f"{page_id}_debug_fillable.png"), fillable)
