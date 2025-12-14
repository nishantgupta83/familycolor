"""
Thumbnail generation for browse grid display.

Outputs 256x256 PNG thumbnails optimized for quick loading.
"""

import cv2
import numpy as np
from pathlib import Path
from typing import Optional

from ..config import Config


class ThumbnailGenerator:
    """Generate thumbnails for coloring page browse grids."""

    def __init__(self, config: Config):
        self.config = config

    def generate(
        self,
        line_art: np.ndarray,
        output_path: Optional[Path] = None
    ) -> np.ndarray:
        """
        Generate a thumbnail from line art.

        Args:
            line_art: Full resolution line art (2048x2048)
            output_path: Optional path to save thumbnail

        Returns:
            256x256 thumbnail as numpy array
        """
        target_size = self.config.thumbnail_size
        h, w = line_art.shape[:2]

        # Calculate scale to fit within target
        scale = target_size / max(h, w)
        new_w = int(w * scale)
        new_h = int(h * scale)

        # Resize using high-quality interpolation
        if len(line_art.shape) == 2:
            # Grayscale
            resized = cv2.resize(
                line_art,
                (new_w, new_h),
                interpolation=cv2.INTER_AREA
            )
            # Create white canvas
            canvas = np.full((target_size, target_size), 255, dtype=np.uint8)
        else:
            # Color
            resized = cv2.resize(
                line_art,
                (new_w, new_h),
                interpolation=cv2.INTER_AREA
            )
            # Create white canvas
            canvas = np.full((target_size, target_size, 3), 255, dtype=np.uint8)

        # Center the resized image
        x_offset = (target_size - new_w) // 2
        y_offset = (target_size - new_h) // 2

        if len(line_art.shape) == 2:
            canvas[y_offset:y_offset + new_h, x_offset:x_offset + new_w] = resized
        else:
            canvas[y_offset:y_offset + new_h, x_offset:x_offset + new_w, :] = resized

        # Add subtle border for better visibility in grid
        canvas = self._add_border(canvas)

        if output_path:
            cv2.imwrite(str(output_path), canvas)

        return canvas

    def _add_border(self, thumbnail: np.ndarray) -> np.ndarray:
        """Add a subtle gray border for visibility."""
        border_color = 240  # Light gray
        border_width = 1

        if len(thumbnail.shape) == 2:
            # Grayscale
            thumbnail[:border_width, :] = border_color
            thumbnail[-border_width:, :] = border_color
            thumbnail[:, :border_width] = border_color
            thumbnail[:, -border_width:] = border_color
        else:
            # Color
            thumbnail[:border_width, :, :] = border_color
            thumbnail[-border_width:, :, :] = border_color
            thumbnail[:, :border_width, :] = border_color
            thumbnail[:, -border_width:, :] = border_color

        return thumbnail

    def generate_preview_with_regions(
        self,
        line_art: np.ndarray,
        label_map: np.ndarray,
        output_path: Optional[Path] = None
    ) -> np.ndarray:
        """
        Generate a thumbnail showing region outlines (for QA).

        Args:
            line_art: Full resolution line art
            label_map: Region label map
            output_path: Optional path to save

        Returns:
            256x256 thumbnail with region outlines
        """
        target_size = self.config.thumbnail_size

        # Find contours of each region
        preview = cv2.cvtColor(line_art, cv2.COLOR_GRAY2BGR) if len(line_art.shape) == 2 else line_art.copy()

        # Get unique regions
        unique_regions = np.unique(label_map)

        for region_id in unique_regions:
            if region_id == 0:
                continue

            # Create mask for this region
            mask = (label_map == region_id).astype(np.uint8) * 255

            # Find contours
            contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

            # Draw contours with region-specific color
            color = self._region_color(region_id)
            cv2.drawContours(preview, contours, -1, color, 1)

        # Resize to thumbnail
        h, w = preview.shape[:2]
        scale = target_size / max(h, w)
        new_w = int(w * scale)
        new_h = int(h * scale)

        resized = cv2.resize(preview, (new_w, new_h), interpolation=cv2.INTER_AREA)

        # Create canvas
        canvas = np.full((target_size, target_size, 3), 255, dtype=np.uint8)
        x_offset = (target_size - new_w) // 2
        y_offset = (target_size - new_h) // 2
        canvas[y_offset:y_offset + new_h, x_offset:x_offset + new_w] = resized

        if output_path:
            cv2.imwrite(str(output_path), canvas)

        return canvas

    def _region_color(self, region_id: int) -> tuple:
        """Generate a consistent color for a region ID."""
        # Use golden ratio for color distribution
        hue = (region_id * 137.508) % 360
        saturation = 0.7
        value = 0.9

        # Convert HSV to BGR
        import colorsys
        r, g, b = colorsys.hsv_to_rgb(hue / 360, saturation, value)
        return (int(b * 255), int(g * 255), int(r * 255))  # BGR for OpenCV
