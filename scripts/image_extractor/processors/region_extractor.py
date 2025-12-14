"""
Region extraction and RGB label-map generation.

Outputs:
- RGB-encoded label map (supports 16M+ regions)
- Region metadata (centroids, bounding boxes, pixel counts)
"""

import cv2
import numpy as np
from pathlib import Path
from typing import Dict, List, Any, Tuple

from ..config import Config


class RegionMetadata:
    """Metadata for a single fillable region."""

    def __init__(
        self,
        region_id: int,
        centroid: Tuple[float, float],
        bounding_box: Tuple[int, int, int, int],
        pixel_count: int
    ):
        self.id = region_id
        self.centroid = centroid
        self.bounding_box = bounding_box  # x, y, width, height
        self.pixel_count = pixel_count

    @property
    def difficulty(self) -> int:
        """Calculate difficulty: 1=easy (large), 2=medium, 3=hard (small)."""
        if self.pixel_count > 50000:
            return 1
        elif self.pixel_count > 10000:
            return 2
        else:
            return 3

    def to_dict(self) -> Dict[str, Any]:
        """Convert to JSON-serializable dictionary."""
        return {
            "id": self.id,
            "centroid": {
                "x": float(self.centroid[0]),
                "y": float(self.centroid[1])
            },
            "boundingBox": {
                "x": int(self.bounding_box[0]),
                "y": int(self.bounding_box[1]),
                "width": int(self.bounding_box[2]),
                "height": int(self.bounding_box[3])
            },
            "pixelCount": int(self.pixel_count),
            "difficulty": self.difficulty
        }


class RegionExtractor:
    """Extract fillable regions and create RGB label maps."""

    def __init__(self, config: Config):
        self.config = config

    def extract(self, fillable_mask: np.ndarray) -> Tuple[np.ndarray, List[RegionMetadata]]:
        """
        Extract regions from fillable mask.

        Args:
            fillable_mask: Binary mask of fillable areas (white = fillable)

        Returns:
            Tuple of (label_map, regions)
            - label_map: 2D array with region IDs (0 = background)
            - regions: List of RegionMetadata objects
        """
        # Connected components analysis
        num_labels, label_map, stats, centroids = cv2.connectedComponentsWithStats(
            fillable_mask,
            connectivity=4
        )

        # Build region metadata (skip label 0 = background)
        regions = []
        for i in range(1, num_labels):
            x, y, w, h, area = stats[i]

            # Skip tiny noise regions
            if area < self.config.min_region_area:
                continue

            region = RegionMetadata(
                region_id=i,
                centroid=(centroids[i][0], centroids[i][1]),
                bounding_box=(x, y, w, h),
                pixel_count=area
            )
            regions.append(region)

        return label_map, regions

    def create_rgb_label_map(self, label_map: np.ndarray) -> np.ndarray:
        """
        Encode region IDs in RGB format.

        RGB encoding: regionId = R + (G * 256) + (B * 65536)
        Supports up to 16,777,215 regions.

        Args:
            label_map: 2D array with integer region IDs

        Returns:
            3-channel RGB image (height x width x 3)
        """
        h, w = label_map.shape
        rgb = np.zeros((h, w, 3), dtype=np.uint8)

        for region_id in np.unique(label_map):
            if region_id == 0:
                continue  # Skip background

            mask = label_map == region_id

            # Encode region ID in RGB
            r = region_id % 256
            g = (region_id // 256) % 256
            b = (region_id // 65536) % 256

            rgb[mask, 0] = r  # Red channel
            rgb[mask, 1] = g  # Green channel
            rgb[mask, 2] = b  # Blue channel

        return rgb

    def save_rgb_label_map(
        self,
        label_map: np.ndarray,
        output_path: Path
    ):
        """Save RGB-encoded label map as PNG."""
        rgb = self.create_rgb_label_map(label_map)

        # OpenCV uses BGR, so convert
        bgr = cv2.cvtColor(rgb, cv2.COLOR_RGB2BGR)
        cv2.imwrite(str(output_path), bgr)

    def save_debug_preview(
        self,
        label_map: np.ndarray,
        output_path: Path
    ):
        """Save random-colored preview for QA visualization."""
        # Generate random colors for each region
        num_regions = label_map.max() + 1
        colors = np.random.randint(50, 255, size=(num_regions, 3), dtype=np.uint8)
        colors[0] = [255, 255, 255]  # Background = white

        # Apply colors
        h, w = label_map.shape
        colored = np.zeros((h, w, 3), dtype=np.uint8)

        for region_id in range(num_regions):
            mask = label_map == region_id
            colored[mask] = colors[region_id]

        cv2.imwrite(str(output_path), cv2.cvtColor(colored, cv2.COLOR_RGB2BGR))

    def build_metadata(
        self,
        page_id: str,
        image_size: Tuple[int, int],
        regions: List[RegionMetadata],
        label_map_name: str
    ) -> Dict[str, Any]:
        """
        Build complete page metadata.

        Args:
            page_id: Unique page identifier
            image_size: (width, height) of the image
            regions: List of RegionMetadata
            label_map_name: Filename of the label map (without extension)

        Returns:
            Dictionary ready for JSON serialization
        """
        return {
            "imageName": page_id,
            "imageSize": {
                "width": image_size[0],
                "height": image_size[1]
            },
            "totalRegions": len(regions),
            "labelMapName": label_map_name,
            "labelEncoding": "rgb24",
            "regions": [r.to_dict() for r in regions]
        }


def decode_region_id(r: int, g: int, b: int) -> int:
    """
    Decode region ID from RGB pixel values.

    This is the inverse of the encoding used in create_rgb_label_map.
    Useful for verifying the label map is correct.
    """
    return r + (g * 256) + (b * 65536)
