"""
Configuration for image extraction pipeline.
"""

from dataclasses import dataclass, field
from enum import Enum
from pathlib import Path
from typing import Optional


class AgeGroup(Enum):
    """Target age groups with different complexity limits."""
    KIDS = "kids"       # 4-8 years: simple, large regions
    FAMILY = "family"   # 8-12 years: moderate complexity
    ADULT = "adult"     # 12+: detailed, small regions


@dataclass
class Config:
    """Pipeline configuration parameters."""

    # Output resolution (iPad-quality)
    target_resolution: int = 2048

    # Thumbnail size
    thumbnail_size: int = 256

    # Line extraction parameters
    line_threshold: int = 128       # Grayscale threshold for line detection
    morph_kernel_size: int = 2      # Morphological kernel size
    morph_iterations: int = 1       # Close iterations (seal small gaps)

    # Region filtering
    min_region_area: int = 500      # Minimum pixels to count as region

    # QA limits per age group
    max_regions: dict = field(default_factory=lambda: {
        AgeGroup.KIDS: 150,
        AgeGroup.FAMILY: 300,
        AgeGroup.ADULT: 1000,
    })

    min_region_pixels: dict = field(default_factory=lambda: {
        AgeGroup.KIDS: 5000,      # Big tap targets for kids
        AgeGroup.FAMILY: 2000,
        AgeGroup.ADULT: 500,
    })

    # Tiny region threshold (% of regions below min size triggers QA fail)
    tiny_region_threshold: float = 0.3  # 30%

    # Debug output
    debug_output: bool = True

    # Output paths (set by pipeline)
    input_path: Optional[Path] = None
    output_dir: Optional[Path] = None

    def get_max_regions(self, age_group: AgeGroup) -> int:
        """Get maximum allowed regions for age group."""
        return self.max_regions.get(age_group, 300)

    def get_min_region_pixels(self, age_group: AgeGroup) -> int:
        """Get minimum region pixel count for age group."""
        return self.min_region_pixels.get(age_group, 2000)


# Category definitions for manifest
CATEGORY_DEFINITIONS = {
    "retro90s": {
        "name": "Retro 90s",
        "icon": "star.fill",
        "color": "#00CED1",
        "ageGroup": "kids",
        "sortOrder": 0,
    },
    "animals": {
        "name": "Simple Animals",
        "icon": "pawprint.fill",
        "color": "#FF6B6B",
        "ageGroup": "kids",
        "sortOrder": 1,
    },
    "butterfly": {
        "name": "Butterfly",
        "icon": "leaf.fill",
        "color": "#9B59B6",
        "ageGroup": "family",
        "sortOrder": 2,
    },
    "nature": {
        "name": "Nature & Flowers",
        "icon": "flower.fill",
        "color": "#2ECC71",
        "ageGroup": "family",
        "sortOrder": 3,
    },
    "vehicles": {
        "name": "Vehicles",
        "icon": "car.fill",
        "color": "#3498DB",
        "ageGroup": "kids",
        "sortOrder": 4,
    },
    "fantasy": {
        "name": "Fairy & Fantasy",
        "icon": "sparkles",
        "color": "#E91E63",
        "ageGroup": "family",
        "sortOrder": 5,
    },
    "mystical": {
        "name": "Mystical Creatures",
        "icon": "flame.fill",
        "color": "#FF9800",
        "ageGroup": "adult",
        "sortOrder": 6,
    },
}
