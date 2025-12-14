#!/usr/bin/env python3
"""
Regenerate metadata JSON from existing label map images.
Analyzes label maps to get accurate region counts, centroids, and bounding boxes.
"""

import cv2
import numpy as np
import json
from pathlib import Path
from collections import defaultdict

def analyze_label_map(label_map_path: Path) -> dict:
    """Analyze a label map image and extract region information."""
    img = cv2.imread(str(label_map_path), cv2.IMREAD_UNCHANGED)
    if img is None:
        raise ValueError(f"Could not load image: {label_map_path}")

    height, width = img.shape[:2]

    # Detect encoding type
    if len(img.shape) == 2:
        # Grayscale
        label_map = img.astype(np.int32)
        encoding = "grayscale"
    else:
        # RGB - decode as: regionId = R + G*256 + B*65536
        img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        label_map = (img_rgb[:,:,0].astype(np.int32) +
                     img_rgb[:,:,1].astype(np.int32) * 256 +
                     img_rgb[:,:,2].astype(np.int32) * 65536)
        encoding = "rgb24"

    # Find unique regions (excluding 0 which is background)
    unique_ids = np.unique(label_map)
    region_ids = [int(rid) for rid in unique_ids if rid > 0]

    regions = []
    for region_id in sorted(region_ids):
        mask = (label_map == region_id)
        pixel_count = int(np.sum(mask))

        # Find bounding box
        coords = np.where(mask)
        if len(coords[0]) == 0:
            continue

        y_min, y_max = int(coords[0].min()), int(coords[0].max())
        x_min, x_max = int(coords[1].min()), int(coords[1].max())

        # Calculate centroid
        centroid_y = float(np.mean(coords[0]))
        centroid_x = float(np.mean(coords[1]))

        # Determine difficulty based on pixel count
        if pixel_count > 50000:
            difficulty = 1  # Easy (large)
        elif pixel_count > 10000:
            difficulty = 2  # Medium
        else:
            difficulty = 3  # Hard (small)

        regions.append({
            "id": region_id,
            "centroid": {"x": round(centroid_x, 2), "y": round(centroid_y, 2)},
            "boundingBox": {
                "x": x_min,
                "y": y_min,
                "width": x_max - x_min + 1,
                "height": y_max - y_min + 1
            },
            "pixelCount": pixel_count,
            "difficulty": difficulty
        })

    return {
        "width": width,
        "height": height,
        "encoding": encoding,
        "totalRegions": len(regions),
        "regions": regions
    }


def regenerate_metadata(image_name: str, assets_path: Path) -> dict:
    """Regenerate metadata for a single image."""
    label_map_path = assets_path / "ColoringPages" / f"{image_name}_labels.imageset" / f"{image_name}_labels.png"

    if not label_map_path.exists():
        print(f"  Warning: Label map not found: {label_map_path}")
        return None

    print(f"  Analyzing {label_map_path.name}...")
    analysis = analyze_label_map(label_map_path)

    # Build metadata structure
    metadata = {
        "imageName": image_name,
        "imageSize": {
            "width": analysis["width"],
            "height": analysis["height"]
        },
        "totalRegions": analysis["totalRegions"],
        "labelMapName": f"{image_name}_labels",
        "labelEncoding": analysis["encoding"] if analysis["encoding"] == "rgb24" else None,
        "regions": analysis["regions"]
    }

    # Remove None values
    metadata = {k: v for k, v in metadata.items() if v is not None}

    return metadata


def main():
    # Path to Assets.xcassets
    project_root = Path(__file__).parent.parent
    assets_path = project_root / "FamilyColorFun" / "Assets.xcassets"
    metadata_output = assets_path / "PageMetadata"

    # Legacy images to reprocess (exclude retro which are already correct)
    legacy_images = [
        "animal_cat",
        "animal_dog",
        "animal_elephant",
        "house_cottage",
        "nature_flower",
        "nature_star",
        "ocean_fish",
        "vehicle_car"
    ]

    print("Regenerating metadata from label maps...\n")

    results = {}
    for image_name in legacy_images:
        print(f"Processing {image_name}...")
        metadata = regenerate_metadata(image_name, assets_path)

        if metadata:
            # Save to PageMetadata folder
            output_path = metadata_output / f"{image_name}.json"
            with open(output_path, 'w') as f:
                json.dump(metadata, f, indent=2)

            results[image_name] = {
                "totalRegions": metadata["totalRegions"],
                "encoding": metadata.get("labelEncoding", "grayscale"),
                "output": str(output_path)
            }
            print(f"  ✓ Saved: {metadata['totalRegions']} regions\n")
        else:
            print(f"  ✗ Skipped\n")

    # Summary
    print("\n" + "="*50)
    print("SUMMARY")
    print("="*50)
    for name, info in results.items():
        print(f"{name}: {info['totalRegions']} regions ({info['encoding']})")

    print(f"\nTotal images processed: {len(results)}")


if __name__ == "__main__":
    main()
