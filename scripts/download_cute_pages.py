#!/usr/bin/env python3
"""
Download cute coloring pages from coloringlover.com
"""

import os
import urllib.request
import ssl
from pathlib import Path

# Create SSL context to handle HTTPS
ssl_context = ssl.create_default_context()
ssl_context.check_hostname = False
ssl_context.verify_mode = ssl.CERT_NONE

# Output directory
output_dir = Path(__file__).parent / "cute_downloads"
output_dir.mkdir(exist_ok=True)

# Cute animal pages
cute_animals = [
    ("cute_lion", "https://www.coloringlover.com/wp-content/uploads/2024/12/Happy-Cute-Lion-Coloring-Page-For-Kids.jpg"),
    ("cute_elephant", "https://www.coloringlover.com/wp-content/uploads/2024/12/Sweet-Cute-Elephant-Coloring-Page-For-Kids.jpg"),
    ("cute_bunny", "https://www.coloringlover.com/wp-content/uploads/2024/12/Playful-Cute-Bunny-Coloring-Page-For-Kids.jpg"),
    ("cute_cat", "https://www.coloringlover.com/wp-content/uploads/2024/12/Playful-Cute-Cat-Coloring-Page-With-Yarn-Ball.jpg"),
    ("cute_fox", "https://www.coloringlover.com/wp-content/uploads/2024/12/Smiling-Cute-Fox-Coloring-Page-Under-Starry-Night.jpg"),
    ("cute_panda", "https://www.coloringlover.com/wp-content/uploads/2024/12/Adorable-Cute-Panda-Coloring-Page-With-Bamboo-Plant.jpg"),
    ("cute_giraffe", "https://www.coloringlover.com/wp-content/uploads/2024/12/Smiling-Cute-Giraffe-Coloring-Page-For-Kids.jpg"),
    ("cute_koala", "https://www.coloringlover.com/wp-content/uploads/2024/12/Adorable-Cute-Koala-Coloring-Sheet-Climbing-A-Tree.jpg"),
    ("cute_penguin", "https://www.coloringlover.com/wp-content/uploads/2024/12/Cute-Penguin-Coloring-Sheet-With-Icy-Mountain-Background.jpg"),
]

# Cute dinosaurs
cute_dinosaurs = [
    ("cute_dino_balloon", "https://www.coloringlover.com/wp-content/uploads/2025/05/Cute-Dinosaur-Flying-With-Balloon-Under-Moonlight-Coloring-Page.jpg"),
    ("cute_dino_trampoline", "https://www.coloringlover.com/wp-content/uploads/2025/05/Happy-Dinosaur-Jumping-On-Trampoline-In-Garden-Coloring-Page.jpg"),
    ("cute_dino_forest", "https://www.coloringlover.com/wp-content/uploads/2025/05/Friendly-Dinosaur-Walking-Through-Peaceful-Forest-Coloring-Page.jpg"),
    ("cute_dino_tricycle", "https://www.coloringlover.com/wp-content/uploads/2025/05/Playful-Dinosaur-Riding-Tricycle-Near-Pond-Coloring-Page.jpg"),
    ("cute_dino_stars", "https://www.coloringlover.com/wp-content/uploads/2025/05/Cute-Dinosaur-With-Stars-Easy-Coloring-Page.jpg"),
    ("cute_dino_hearts", "https://www.coloringlover.com/wp-content/uploads/2025/05/Happy-Dinosaur-With-Hearts-Preschool-Coloring-Page.jpg"),
    ("cute_dino_rainbow", "https://www.coloringlover.com/wp-content/uploads/2025/05/Smiling-Dinosaur-And-Rainbow-Easy-Coloring-Sheet.jpg"),
    ("cute_triceratops", "https://www.coloringlover.com/wp-content/uploads/2025/05/Triceratops-In-Flower-Garden-Easy-Coloring-Page.jpg"),
    ("cute_trex_icecream", "https://www.coloringlover.com/wp-content/uploads/2025/05/T-Rex-Happily-Holding-Ice-Cream-With-Hearts-Coloring-Page.jpg"),
]

# Easy coloring pages
easy_pages = [
    ("easy_rainbow", "https://www.coloringlover.com/wp-content/uploads/2025/01/Easy-Rainbow-Coloring-Page-With-Fluffy-Clouds.jpg"),
    ("easy_balloons", "https://www.coloringlover.com/wp-content/uploads/2025/01/Simple-Balloons-Coloring-Page-With-Three-Floating-Balloons.jpg"),
    ("easy_dog", "https://www.coloringlover.com/wp-content/uploads/2025/01/Easy-To-Color-Sitting-Cute-Dog-Coloring-Page.jpg"),
    ("easy_cat", "https://www.coloringlover.com/wp-content/uploads/2025/01/Easy-To-Color-Sitting-Cat-Coloring-Page.jpg"),
    ("easy_turtle", "https://www.coloringlover.com/wp-content/uploads/2025/01/Easy-To-Color-Smiling-Turtle-Coloring-Page.jpg"),
    ("easy_rabbit", "https://www.coloringlover.com/wp-content/uploads/2025/01/Easy-To-Color-Happy-Rabbit-Sitting-Coloring-Sheet.jpg"),
    ("easy_whale", "https://www.coloringlover.com/wp-content/uploads/2025/01/Easy-To-Color-Smiling-Whale-Coloring-Page.jpg"),
    ("easy_octopus", "https://www.coloringlover.com/wp-content/uploads/2025/01/Easy-To-Color-Happy-Octopus-Coloring-Page.jpg"),
    ("easy_sunflower", "https://www.coloringlover.com/wp-content/uploads/2025/01/Easy-Sunflower-Coloring-Page-With-Decorative-Petal-Design.jpg"),
    ("easy_car", "https://www.coloringlover.com/wp-content/uploads/2025/01/Easy-Car-Coloring-Page-Featuring-A-Classic-Compact-Vehicle.jpg"),
    ("easy_train", "https://www.coloringlover.com/wp-content/uploads/2025/01/Simple-Train-Coloring-Page-With-Vintage-Steam-Engine-Design.jpg"),
    ("easy_airplane", "https://www.coloringlover.com/wp-content/uploads/2025/01/Easy-Airplane-Coloring-Page-With-Clear-And-Bold-Outlines.jpg"),
    ("easy_house", "https://www.coloringlover.com/wp-content/uploads/2025/01/Easy-To-Color-Countryside-House-Coloring-Page.jpg"),
]

def download_image(name, url):
    """Download a single image."""
    output_path = output_dir / f"{name}.jpg"
    if output_path.exists():
        print(f"  Skipping {name} (already exists)")
        return True

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

def main():
    print("Downloading cute coloring pages...")
    print(f"Output directory: {output_dir}\n")

    success_count = 0
    total_count = 0

    print("Cute Animals:")
    for name, url in cute_animals:
        total_count += 1
        if download_image(name, url):
            success_count += 1

    print("\nCute Dinosaurs:")
    for name, url in cute_dinosaurs:
        total_count += 1
        if download_image(name, url):
            success_count += 1

    print("\nEasy Pages:")
    for name, url in easy_pages:
        total_count += 1
        if download_image(name, url):
            success_count += 1

    print(f"\nComplete: {success_count}/{total_count} images downloaded")
    print(f"Images saved to: {output_dir}")

if __name__ == "__main__":
    main()
