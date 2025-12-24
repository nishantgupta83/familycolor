#!/usr/bin/env python3
"""
Download cute underwater coloring pages to replace bad placeholder images
"""

import os
import urllib.request
import ssl
import json
import shutil
from pathlib import Path

ssl_context = ssl.create_default_context()
ssl_context.check_hostname = False
ssl_context.verify_mode = ssl.CERT_NONE

script_dir = Path(__file__).parent
output_dir = script_dir / "underwater_downloads"
assets_dir = script_dir.parent / "FamilyColorFun" / "Assets.xcassets" / "ColoringPages"
output_dir.mkdir(exist_ok=True)

# Better underwater images
underwater_images = [
    # Seahorse (replacing the terrible one)
    ("underwater_seahorse", "https://www.coloringlover.com/wp-content/uploads/2024/10/Baby-Dolphin-And-Seahorse-In-Coral-Reef-Coloring-Page.jpg"),

    # Better turtles
    ("underwater_turtle", "https://www.coloringlover.com/wp-content/uploads/2024/11/Cute-Turtle-On-Mushroom-Coloring-Sheet.jpg"),
    ("cute_sea_turtle", "https://www.coloringlover.com/wp-content/uploads/2024/11/Sea-Turtle-Coral-Reef-Coloring-Page.jpg"),
    ("cute_baby_turtle", "https://www.coloringlover.com/wp-content/uploads/2024/11/Baby-Turtle-With-Bubbles-Coloring-Page.jpg"),

    # Better octopus
    ("underwater_octopus", "https://www.coloringlover.com/wp-content/uploads/2025/01/Easy-To-Color-Happy-Octopus-Coloring-Page.jpg"),

    # Cute fish
    ("cute_clownfish", "https://www.coloringlover.com/wp-content/uploads/2025/05/Cute-Clown-Fish-Swimming-Through-Coral-Reef-Coloring-Page.jpg"),
    ("cute_fish_couple", "https://www.coloringlover.com/wp-content/uploads/2025/05/Cute-Fish-Couple-Surrounded-By-Hearts-Coloring-Page.jpg"),
    ("cute_angelfish", "https://www.coloringlover.com/wp-content/uploads/2025/05/Cute-Angelfish-Swimming-Among-Sea-Plants-Coloring-Page.jpg"),
    ("ocean_fish", "https://www.coloringlover.com/wp-content/uploads/2025/05/Kawaii-Fish-Introducing-Itself-Underwater-Coloring-Page.jpg"),

    # Cute dolphins
    ("cute_dolphin", "https://www.coloringlover.com/wp-content/uploads/2024/10/Cute-Baby-Dolphin-Jumping-With-Rainbow-Coloring-Page.jpg"),
    ("cute_dolphin_fish", "https://www.coloringlover.com/wp-content/uploads/2024/10/Cute-Baby-Dolphin-Swimming-With-Fish-Coloring-Page.jpg"),
    ("dolphin_beachball", "https://www.coloringlover.com/wp-content/uploads/2024/10/Happy-Dolphin-Playing-With-A-Beach-Ball-Coloring-Sheet.jpg"),

    # Whale
    ("cute_whale", "https://www.coloringlover.com/wp-content/uploads/2024/11/Whale-And-Turtles-Coloring-Page-With-Bubbles.jpg"),
]


def download_image(name, url):
    """Download a single image."""
    output_path = output_dir / f"{name}.jpg"

    try:
        req = urllib.request.Request(
            url,
            headers={'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'}
        )
        with urllib.request.urlopen(req, context=ssl_context, timeout=30) as response:
            data = response.read()
            with open(output_path, 'wb') as f:
                f.write(data)
        print(f"  Downloaded: {name}")
        return True
    except Exception as e:
        print(f"  Failed {name}: {e}")
        return False


def create_imageset(image_name, source_path):
    """Create an imageset directory with Contents.json and image."""
    imageset_dir = assets_dir / f"{image_name}.imageset"

    # Remove existing if present
    if imageset_dir.exists():
        shutil.rmtree(imageset_dir)

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
            {"idiom": "universal", "scale": "2x"},
            {"idiom": "universal", "scale": "3x"}
        ],
        "info": {"author": "xcode", "version": 1}
    }

    contents_path = imageset_dir / "Contents.json"
    with open(contents_path, 'w') as f:
        json.dump(contents, f, indent=2)

    print(f"  Created imageset: {image_name}")


def main():
    print("Downloading cute underwater coloring pages...")
    print(f"Output: {output_dir}\n")

    success = 0
    for name, url in underwater_images:
        if download_image(name, url):
            success += 1

    print(f"\nDownloaded {success}/{len(underwater_images)} images")

    print("\nCreating imagesets...")
    for image_file in output_dir.glob("*.jpg"):
        create_imageset(image_file.stem, image_file)

    print("\nDone! Rebuild the app to see the new images.")


if __name__ == "__main__":
    main()
