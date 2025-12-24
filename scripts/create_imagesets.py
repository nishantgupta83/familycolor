#!/usr/bin/env python3
"""
Create Xcode imagesets from downloaded cute coloring pages
"""

import os
import json
import shutil
from pathlib import Path

# Paths
script_dir = Path(__file__).parent
downloads_dir = script_dir / "cute_downloads"
assets_dir = script_dir.parent / "FamilyColorFun" / "Assets.xcassets" / "ColoringPages"

def create_imageset(image_name, source_path):
    """Create an imageset directory with Contents.json and image."""
    imageset_dir = assets_dir / f"{image_name}.imageset"
    imageset_dir.mkdir(exist_ok=True)

    # Copy image
    dest_image = imageset_dir / f"{image_name}.jpg"
    shutil.copy(source_path, dest_image)

    # Create Contents.json
    contents = {
        "images": [
            {
                "filename": f"{image_name}.jpg",
                "idiom": "universal",
                "scale": "1x"
            },
            {
                "idiom": "universal",
                "scale": "2x"
            },
            {
                "idiom": "universal",
                "scale": "3x"
            }
        ],
        "info": {
            "author": "xcode",
            "version": 1
        }
    }

    contents_path = imageset_dir / "Contents.json"
    with open(contents_path, 'w') as f:
        json.dump(contents, f, indent=2)

    print(f"  Created: {image_name}.imageset")

def main():
    print("Creating Xcode imagesets...")
    print(f"Source: {downloads_dir}")
    print(f"Destination: {assets_dir}\n")

    if not downloads_dir.exists():
        print("Error: Downloads directory not found!")
        return

    # Process all downloaded images
    for image_file in sorted(downloads_dir.glob("*.jpg")):
        image_name = image_file.stem
        create_imageset(image_name, image_file)

    print("\nImagesets created successfully!")

if __name__ == "__main__":
    main()
