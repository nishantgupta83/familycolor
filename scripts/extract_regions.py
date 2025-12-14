#!/usr/bin/env python3
"""
Extract colorable regions from coloring page images using OpenCV.
Outputs: label-map PNG + JSON metadata for each image.
"""

import cv2
import numpy as np
import json
from pathlib import Path
from typing import Dict, Any

# Configuration (tune per asset style)
MORPH_KERNEL_SIZE = 2  # 2x2 or 3x3 - smaller = less region merging
MORPH_ITERATIONS = 1   # Keep low to avoid bridging thin lines
MIN_REGION_AREA = 500  # Filter noise regions
DEBUG_OUTPUT = True    # Output intermediate images for QA


def extract_regions(image_path: Path, output_dir: Path = None) -> Dict[str, Any]:
    """
    CORRECT pipeline for line-art coloring pages:
    1. Threshold BLACK lines (not white)
    2. Morphological close to seal gaps (tunable)
    3. Invert to get fillable areas
    4. Remove outside background via border flood-fill
    5. Clean binary threshold
    6. Connected components on interior regions
    """
    if output_dir is None:
        output_dir = image_path.parent

    img = cv2.imread(str(image_path), cv2.IMREAD_GRAYSCALE)
    if img is None:
        raise ValueError(f"Could not read image: {image_path}")

    h, w = img.shape

    # Step 1: Threshold to get BLACK lines (value < 128 = line)
    _, lines = cv2.threshold(img, 128, 255, cv2.THRESH_BINARY_INV)

    # Step 2: Morphological close to seal small gaps (configurable)
    kernel = np.ones((MORPH_KERNEL_SIZE, MORPH_KERNEL_SIZE), np.uint8)
    lines_closed = cv2.morphologyEx(lines, cv2.MORPH_CLOSE, kernel, iterations=MORPH_ITERATIONS)

    # Step 3: Invert to get WHITE fillable areas
    fillable = cv2.bitwise_not(lines_closed)

    # Step 4: Remove outside background (flood-fill from all corners)
    mask = np.zeros((h + 2, w + 2), np.uint8)
    cv2.floodFill(fillable, mask, (0, 0), 0)
    cv2.floodFill(fillable, mask, (w - 1, 0), 0)
    cv2.floodFill(fillable, mask, (0, h - 1), 0)
    cv2.floodFill(fillable, mask, (w - 1, h - 1), 0)

    # Step 5: CRITICAL - Force clean binary after flood-fill modifications
    fillable = (fillable > 0).astype(np.uint8) * 255

    # Step 6: Connected components on remaining interior regions
    num_labels, label_map, stats, centroids = cv2.connectedComponentsWithStats(
        fillable, connectivity=4
    )

    # Build region metadata (skip label 0 = background)
    regions = []
    for i in range(1, num_labels):
        x, y, rw, rh, area = stats[i]
        if area > MIN_REGION_AREA:
            # Difficulty: 1 = easy (large), 2 = medium, 3 = hard (small)
            difficulty = 1 if area > 50000 else (2 if area > 10000 else 3)
            regions.append({
                "id": i,
                "centroid": {"x": float(centroids[i][0]), "y": float(centroids[i][1])},
                "boundingBox": {"x": int(x), "y": int(y), "width": int(rw), "height": int(rh)},
                "pixelCount": int(area),
                "difficulty": difficulty
            })

    # Validate region count (uint8 limit = 255)
    if len(regions) > 250:
        print(f"WARNING: {len(regions)} regions exceeds uint8 safe limit!")

    # Save label-map as 8-bit PNG (safe for <50 regions per spec)
    label_map_name = f"{image_path.stem}_labels"
    label_map_path = output_dir / f"{label_map_name}.png"
    cv2.imwrite(str(label_map_path), label_map.astype(np.uint8))

    # Debug output for QA
    if DEBUG_OUTPUT:
        cv2.imwrite(str(output_dir / f"{image_path.stem}_debug_lines.png"), lines)
        cv2.imwrite(str(output_dir / f"{image_path.stem}_debug_fillable.png"), fillable)
        # Color-coded label map for visualization
        colored = cv2.applyColorMap((label_map * 10).astype(np.uint8), cv2.COLORMAP_JET)
        cv2.imwrite(str(output_dir / f"{image_path.stem}_debug_colored.png"), colored)

    metadata = {
        "imageName": image_path.stem,
        "imageSize": {"width": w, "height": h},
        "totalRegions": len(regions),
        "labelMapName": label_map_name,
        "regions": regions
    }

    # Save JSON metadata
    json_path = output_dir / f"{image_path.stem}.json"
    with open(json_path, 'w') as f:
        json.dump(metadata, f, indent=2)

    print(f"Extracted {len(regions)} regions from {image_path.name}")
    return metadata


def process_directory(input_dir: Path, output_dir: Path = None):
    """Process all PNG images in a directory."""
    if output_dir is None:
        output_dir = input_dir

    output_dir.mkdir(parents=True, exist_ok=True)

    for image_path in input_dir.glob("*.png"):
        # Skip label maps and debug images
        if "_labels" in image_path.stem or "_debug" in image_path.stem:
            continue
        try:
            extract_regions(image_path, output_dir)
        except Exception as e:
            print(f"Error processing {image_path}: {e}")


if __name__ == "__main__":
    import sys

    if len(sys.argv) < 2:
        print("Usage: python extract_regions.py <image_or_directory>")
        sys.exit(1)

    path = Path(sys.argv[1])
    output = Path(sys.argv[2]) if len(sys.argv) > 2 else None

    if path.is_file():
        extract_regions(path, output)
    elif path.is_dir():
        process_directory(path, output)
    else:
        print(f"Path not found: {path}")
        sys.exit(1)
