"""
CDN Manifest Builder

Generates manifest.json for the content delivery system.
Includes checksums for integrity verification.
"""

import json
import hashlib
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List, Optional, Any

from .config import Config, AgeGroup, CATEGORY_DEFINITIONS


@dataclass
class PageAssets:
    """Asset paths for a single page."""
    thumb: str
    image: str
    labels: str
    metadata: str


@dataclass
class PageChecksums:
    """SHA256 checksums for asset integrity."""
    thumb: str
    image: str
    labels: str
    metadata: str


@dataclass
class PageEntry:
    """A single page entry in the manifest."""
    id: str
    category_id: str
    name: str
    age_group: str
    content_tier: str
    difficulty: int
    region_count: int
    image_resolution: int
    version: str
    assets: PageAssets
    checksums: PageChecksums

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "categoryId": self.category_id,
            "name": self.name,
            "ageGroup": self.age_group,
            "contentTier": self.content_tier,
            "difficulty": self.difficulty,
            "regionCount": self.region_count,
            "imageResolution": self.image_resolution,
            "version": self.version,
            "assets": {
                "thumb": self.assets.thumb,
                "image": self.assets.image,
                "labels": self.assets.labels,
                "metadata": self.assets.metadata,
            },
            "checksums": {
                "thumb": self.checksums.thumb,
                "image": self.checksums.image,
                "labels": self.checksums.labels,
                "metadata": self.checksums.metadata,
            }
        }


@dataclass
class CategoryEntry:
    """A category entry in the manifest."""
    id: str
    name: str
    icon: str
    color: str
    age_group: str
    sort_order: int

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "name": self.name,
            "icon": self.icon,
            "color": self.color,
            "ageGroup": self.age_group,
            "sortOrder": self.sort_order,
        }


class ManifestBuilder:
    """Build CDN manifest from processed pages."""

    VERSION = "1.0.0"
    MIN_APP_VERSION = "1.0.0"
    LABEL_ENCODING = "rgb24"

    def __init__(self, base_url: str = "https://cdn.familycolorfun.app/v1"):
        self.base_url = base_url
        self.pages: List[PageEntry] = []
        self.categories: Dict[str, CategoryEntry] = {}

    def add_category(self, category_id: str) -> CategoryEntry:
        """Add a category from predefined definitions."""
        if category_id in self.categories:
            return self.categories[category_id]

        definition = CATEGORY_DEFINITIONS.get(category_id)
        if not definition:
            raise ValueError(f"Unknown category: {category_id}")

        entry = CategoryEntry(
            id=category_id,
            name=definition["name"],
            icon=definition["icon"],
            color=definition["color"],
            age_group=definition["ageGroup"],
            sort_order=definition["sortOrder"],
        )
        self.categories[category_id] = entry
        return entry

    def add_page(
        self,
        page_id: str,
        category_id: str,
        name: str,
        processed_dir: Path,
        age_group: AgeGroup,
        region_count: int,
        difficulty: int = 1,
        content_tier: str = "mvp",
        version: str = "1.0.0",
        image_resolution: int = 2048,
    ) -> PageEntry:
        """
        Add a processed page to the manifest.

        Args:
            page_id: Unique identifier (e.g., "retro_boombox_01")
            category_id: Category ID (e.g., "retro90s")
            name: Display name (e.g., "Boom Box")
            processed_dir: Directory containing processed assets
            age_group: Target age group
            region_count: Number of fillable regions
            difficulty: 1=easy, 2=medium, 3=hard
            content_tier: "mvp", "v1.1", "v2.0", etc.
            version: Asset version
            image_resolution: Image resolution (typically 2048)
        """
        # Ensure category exists
        if category_id not in self.categories:
            self.add_category(category_id)

        # Define asset paths (relative to CDN base)
        asset_prefix = f"{page_id}/"
        assets = PageAssets(
            thumb=f"{asset_prefix}thumb.png",
            image=f"{asset_prefix}image.png",
            labels=f"{asset_prefix}labels.png",
            metadata=f"{asset_prefix}metadata.json",
        )

        # Calculate checksums
        checksums = self._calculate_checksums(processed_dir, page_id)

        entry = PageEntry(
            id=page_id,
            category_id=category_id,
            name=name,
            age_group=age_group.value,
            content_tier=content_tier,
            difficulty=difficulty,
            region_count=region_count,
            image_resolution=image_resolution,
            version=version,
            assets=assets,
            checksums=checksums,
        )

        self.pages.append(entry)
        return entry

    def _calculate_checksums(self, processed_dir: Path, page_id: str) -> PageChecksums:
        """Calculate SHA256 checksums for all assets."""
        page_dir = processed_dir / page_id

        def sha256_file(path: Path) -> str:
            if not path.exists():
                return "sha256:missing"
            h = hashlib.sha256()
            with open(path, "rb") as f:
                for chunk in iter(lambda: f.read(8192), b""):
                    h.update(chunk)
            return f"sha256:{h.hexdigest()}"

        return PageChecksums(
            thumb=sha256_file(page_dir / "thumb.png"),
            image=sha256_file(page_dir / "image.png"),
            labels=sha256_file(page_dir / "labels.png"),
            metadata=sha256_file(page_dir / "metadata.json"),
        )

    def build(self) -> Dict[str, Any]:
        """Build the complete manifest dictionary."""
        # Sort categories by sort_order
        sorted_categories = sorted(
            self.categories.values(),
            key=lambda c: c.sort_order
        )

        return {
            "version": self.VERSION,
            "minAppVersion": self.MIN_APP_VERSION,
            "generatedAt": datetime.now(timezone.utc).isoformat(),
            "baseUrl": self.base_url,
            "labelEncoding": self.LABEL_ENCODING,
            "categories": [c.to_dict() for c in sorted_categories],
            "pages": [p.to_dict() for p in self.pages],
            "pageCount": len(self.pages),
        }

    def save(self, output_path: Path):
        """Save manifest to JSON file."""
        manifest = self.build()
        with open(output_path, "w") as f:
            json.dump(manifest, f, indent=2)

    @classmethod
    def from_processed_directory(
        cls,
        processed_dir: Path,
        base_url: str = "https://cdn.familycolorfun.app/v1"
    ) -> "ManifestBuilder":
        """
        Build manifest from a directory of processed pages.

        Expects structure:
        processed/
          page_id_1/
            image.png
            labels.png
            metadata.json
            thumb.png
          page_id_2/
            ...
        """
        builder = cls(base_url)

        for page_dir in sorted(processed_dir.iterdir()):
            if not page_dir.is_dir():
                continue

            if page_dir.name.startswith("_") or page_dir.name.startswith("."):
                continue

            metadata_path = page_dir / "metadata.json"
            if not metadata_path.exists():
                continue

            # Load metadata
            with open(metadata_path) as f:
                metadata = json.load(f)

            # Extract info from page_id (e.g., "retro_boombox_01")
            page_id = page_dir.name
            parts = page_id.rsplit("_", 1)

            # Try to infer category from page_id prefix
            category_id = cls._infer_category(page_id)
            name = cls._generate_display_name(page_id)

            # Get age group from category definition
            cat_def = CATEGORY_DEFINITIONS.get(category_id, {})
            age_group_str = cat_def.get("ageGroup", "family")
            age_group = AgeGroup(age_group_str)

            builder.add_page(
                page_id=page_id,
                category_id=category_id,
                name=name,
                processed_dir=processed_dir,
                age_group=age_group,
                region_count=metadata.get("totalRegions", 0),
                difficulty=cls._calculate_difficulty(metadata),
            )

        return builder

    @staticmethod
    def _infer_category(page_id: str) -> str:
        """Infer category from page ID prefix."""
        page_id_lower = page_id.lower()

        if "retro" in page_id_lower or "90s" in page_id_lower:
            return "retro90s"
        elif "butterfly" in page_id_lower:
            return "butterfly"
        elif "animal" in page_id_lower:
            return "animals"
        elif "nature" in page_id_lower or "flower" in page_id_lower:
            return "nature"
        elif "vehicle" in page_id_lower or "car" in page_id_lower:
            return "vehicles"
        elif "fairy" in page_id_lower or "fantasy" in page_id_lower:
            return "fantasy"
        elif "mystical" in page_id_lower or "phoenix" in page_id_lower or "dragon" in page_id_lower:
            return "mystical"
        else:
            return "animals"  # Default

    @staticmethod
    def _generate_display_name(page_id: str) -> str:
        """Generate display name from page ID."""
        # Remove category prefix and number suffix
        # e.g., "retro_boombox_01" -> "Boombox"
        parts = page_id.split("_")

        # Filter out category keywords and numbers
        skip_words = {"retro", "90s", "butterfly", "animal", "nature", "vehicle", "mystical", "fantasy"}
        filtered = [p for p in parts if p.lower() not in skip_words and not p.isdigit()]

        if filtered:
            return " ".join(p.title() for p in filtered)
        return page_id.replace("_", " ").title()

    @staticmethod
    def _calculate_difficulty(metadata: Dict[str, Any]) -> int:
        """Calculate overall page difficulty from metadata."""
        regions = metadata.get("regions", [])
        if not regions:
            return 1

        # Average difficulty of all regions
        avg_difficulty = sum(r.get("difficulty", 2) for r in regions) / len(regions)

        if avg_difficulty < 1.5:
            return 1
        elif avg_difficulty < 2.5:
            return 2
        else:
            return 3
