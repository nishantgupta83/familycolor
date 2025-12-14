#!/usr/bin/env python3
"""Generate simple coloring page PNG images for FamilyColorFun app with region metadata."""

import os
import json
from pathlib import Path
from PIL import Image, ImageDraw

# Output directories
ASSETS_DIR = "FamilyColorFun/Assets.xcassets/ColoringPages"
METADATA_DIR = "FamilyColorFun/Assets.xcassets/PageMetadata"
SIZE = (1024, 1024)
LINE_WIDTH = 8

# Import region extraction (add scripts to path)
import sys
sys.path.insert(0, str(Path(__file__).parent / "scripts"))
from extract_regions import extract_regions


def create_imageset(name, image):
    """Create an imageset folder with PNG, label-map, and metadata."""
    imageset_dir = os.path.join(ASSETS_DIR, f"{name}.imageset")
    os.makedirs(imageset_dir, exist_ok=True)

    # Save main PNG
    image_path = os.path.join(imageset_dir, f"{name}.png")
    image.save(image_path)

    # Create Contents.json for imageset
    contents = """{
  "images" : [
    {
      "filename" : "%s.png",
      "idiom" : "universal",
      "scale" : "1x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}""" % name
    with open(os.path.join(imageset_dir, "Contents.json"), "w") as f:
        f.write(contents)

    # Extract regions and generate metadata
    try:
        metadata = extract_regions(Path(image_path), Path(imageset_dir))
        print(f"Created: {name} ({metadata['totalRegions']} regions)")

        # Also save metadata to PageMetadata folder for easy access
        os.makedirs(METADATA_DIR, exist_ok=True)
        metadata_path = os.path.join(METADATA_DIR, f"{name}.json")
        with open(metadata_path, "w") as f:
            json.dump(metadata, f, indent=2)

        # Create imageset for label map
        create_label_imageset(name, imageset_dir)

    except Exception as e:
        print(f"Created: {name} (region extraction failed: {e})")


def create_label_imageset(name, source_dir):
    """Create an imageset for the label map PNG."""
    label_name = f"{name}_labels"
    label_imageset_dir = os.path.join(ASSETS_DIR, f"{label_name}.imageset")
    os.makedirs(label_imageset_dir, exist_ok=True)

    # Move label map to its own imageset
    import shutil
    src_label = os.path.join(source_dir, f"{label_name}.png")
    dst_label = os.path.join(label_imageset_dir, f"{label_name}.png")
    if os.path.exists(src_label):
        shutil.move(src_label, dst_label)

    # Create Contents.json
    contents = """{
  "images" : [
    {
      "filename" : "%s.png",
      "idiom" : "universal",
      "scale" : "1x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}""" % label_name
    with open(os.path.join(label_imageset_dir, "Contents.json"), "w") as f:
        f.write(contents)


def draw_cat():
    """Draw a simple cat face."""
    img = Image.new('RGB', SIZE, 'white')
    draw = ImageDraw.Draw(img)

    # Head (circle)
    draw.ellipse([200, 200, 824, 824], outline='black', width=LINE_WIDTH)

    # Left ear (triangle)
    draw.polygon([(250, 250), (180, 80), (380, 200)], outline='black', width=LINE_WIDTH)
    # Right ear
    draw.polygon([(774, 250), (844, 80), (644, 200)], outline='black', width=LINE_WIDTH)

    # Eyes
    draw.ellipse([320, 380, 420, 500], outline='black', width=LINE_WIDTH)
    draw.ellipse([604, 380, 704, 500], outline='black', width=LINE_WIDTH)

    # Nose (triangle)
    draw.polygon([(512, 520), (462, 600), (562, 600)], outline='black', width=LINE_WIDTH)

    # Mouth
    draw.arc([400, 580, 512, 700], 0, 180, fill='black', width=LINE_WIDTH)
    draw.arc([512, 580, 624, 700], 0, 180, fill='black', width=LINE_WIDTH)

    # Whiskers
    draw.line([(320, 600), (150, 550)], fill='black', width=4)
    draw.line([(320, 640), (150, 640)], fill='black', width=4)
    draw.line([(320, 680), (150, 730)], fill='black', width=4)
    draw.line([(704, 600), (874, 550)], fill='black', width=4)
    draw.line([(704, 640), (874, 640)], fill='black', width=4)
    draw.line([(704, 680), (874, 730)], fill='black', width=4)

    return img

def draw_dog():
    """Draw a simple dog face."""
    img = Image.new('RGB', SIZE, 'white')
    draw = ImageDraw.Draw(img)

    # Head
    draw.ellipse([200, 200, 824, 824], outline='black', width=LINE_WIDTH)

    # Floppy ears
    draw.ellipse([100, 200, 300, 500], outline='black', width=LINE_WIDTH)
    draw.ellipse([724, 200, 924, 500], outline='black', width=LINE_WIDTH)

    # Eyes
    draw.ellipse([340, 380, 440, 480], outline='black', width=LINE_WIDTH)
    draw.ellipse([584, 380, 684, 480], outline='black', width=LINE_WIDTH)

    # Nose (big oval)
    draw.ellipse([430, 530, 594, 660], outline='black', width=LINE_WIDTH)

    # Mouth
    draw.line([(512, 660), (512, 720)], fill='black', width=LINE_WIDTH)
    draw.arc([400, 680, 512, 780], 0, 180, fill='black', width=LINE_WIDTH)
    draw.arc([512, 680, 624, 780], 0, 180, fill='black', width=LINE_WIDTH)

    # Tongue
    draw.ellipse([470, 720, 554, 820], outline='black', width=LINE_WIDTH)

    return img

def draw_elephant():
    """Draw a simple elephant."""
    img = Image.new('RGB', SIZE, 'white')
    draw = ImageDraw.Draw(img)

    # Body
    draw.ellipse([300, 400, 900, 800], outline='black', width=LINE_WIDTH)

    # Head
    draw.ellipse([100, 300, 500, 700], outline='black', width=LINE_WIDTH)

    # Trunk
    draw.arc([50, 450, 250, 900], 90, 270, fill='black', width=LINE_WIDTH)
    draw.line([(150, 450), (150, 550)], fill='black', width=LINE_WIDTH)

    # Ear
    draw.ellipse([50, 300, 250, 550], outline='black', width=LINE_WIDTH)

    # Eye
    draw.ellipse([280, 420, 340, 480], outline='black', width=LINE_WIDTH)

    # Legs
    draw.rectangle([400, 700, 480, 900], outline='black', width=LINE_WIDTH)
    draw.rectangle([520, 700, 600, 900], outline='black', width=LINE_WIDTH)
    draw.rectangle([680, 700, 760, 900], outline='black', width=LINE_WIDTH)
    draw.rectangle([800, 700, 880, 900], outline='black', width=LINE_WIDTH)

    # Tail
    draw.arc([850, 550, 980, 700], 180, 360, fill='black', width=LINE_WIDTH)

    return img

def draw_fish():
    """Draw a simple fish."""
    img = Image.new('RGB', SIZE, 'white')
    draw = ImageDraw.Draw(img)

    # Body (oval)
    draw.ellipse([200, 300, 750, 700], outline='black', width=LINE_WIDTH)

    # Tail
    draw.polygon([(700, 500), (900, 300), (900, 700)], outline='black', width=LINE_WIDTH)

    # Eye
    draw.ellipse([300, 420, 380, 500], outline='black', width=LINE_WIDTH)
    draw.ellipse([320, 440, 360, 480], outline='black', width=LINE_WIDTH)

    # Mouth
    draw.arc([200, 460, 280, 540], 270, 90, fill='black', width=LINE_WIDTH)

    # Fins
    draw.polygon([(450, 300), (550, 150), (550, 300)], outline='black', width=LINE_WIDTH)
    draw.polygon([(450, 700), (550, 850), (550, 700)], outline='black', width=LINE_WIDTH)

    # Scales pattern
    for y in range(380, 620, 80):
        for x in range(350, 650, 80):
            draw.arc([x, y, x+60, y+60], 0, 180, fill='black', width=4)

    return img

def draw_car():
    """Draw a simple car."""
    img = Image.new('RGB', SIZE, 'white')
    draw = ImageDraw.Draw(img)

    # Body
    draw.rectangle([150, 450, 874, 700], outline='black', width=LINE_WIDTH)

    # Top/cabin
    draw.polygon([(300, 450), (350, 300), (674, 300), (724, 450)], outline='black', width=LINE_WIDTH)

    # Windows
    draw.polygon([(360, 440), (400, 320), (500, 320), (500, 440)], outline='black', width=LINE_WIDTH)
    draw.polygon([(520, 440), (520, 320), (620, 320), (660, 440)], outline='black', width=LINE_WIDTH)

    # Wheels
    draw.ellipse([220, 620, 380, 780], outline='black', width=LINE_WIDTH)
    draw.ellipse([260, 660, 340, 740], outline='black', width=LINE_WIDTH)
    draw.ellipse([644, 620, 804, 780], outline='black', width=LINE_WIDTH)
    draw.ellipse([684, 660, 764, 740], outline='black', width=LINE_WIDTH)

    # Headlights
    draw.ellipse([160, 520, 220, 580], outline='black', width=LINE_WIDTH)
    draw.ellipse([804, 520, 864, 580], outline='black', width=LINE_WIDTH)

    # Door handle
    draw.rectangle([550, 520, 620, 540], outline='black', width=LINE_WIDTH)

    return img

def draw_house():
    """Draw a simple house with properly separated regions."""
    img = Image.new('RGB', SIZE, 'white')
    draw = ImageDraw.Draw(img)

    LW = LINE_WIDTH

    # 1. Roof - closed triangle (draw FIRST so house overlaps it cleanly)
    draw.polygon([(150, 400), (512, 100), (874, 400)], outline='black', width=LW)

    # 2. House body - SINGLE outer rectangle for continuous boundary
    draw.rectangle([200, 400, 824, 850], outline='black', width=LW)

    # 3. Seal the roof-house junction with an extra line
    draw.line([(200, 400), (824, 400)], fill='black', width=LW)

    # 4. Internal vertical walls (door column separators)
    draw.line([(430, 400), (430, 850)], fill='black', width=LW)
    draw.line([(594, 400), (594, 850)], fill='black', width=LW)

    # 5. Horizontal divider above door
    draw.line([(430, 600), (594, 600)], fill='black', width=LW)

    # 6. Door knob
    draw.ellipse([545, 705, 575, 735], outline='black', width=LW)

    # 7. Left window - completely closed rectangle with dividers
    draw.rectangle([260, 490, 380, 580], outline='black', width=LW)
    draw.line([(320, 490), (320, 580)], fill='black', width=LW)
    draw.line([(260, 535), (380, 535)], fill='black', width=LW)

    # 8. Right window - completely closed rectangle with dividers
    draw.rectangle([644, 490, 764, 580], outline='black', width=LW)
    draw.line([(704, 490), (704, 580)], fill='black', width=LW)
    draw.line([(644, 535), (764, 535)], fill='black', width=LW)

    # 9. Chimney - positioned on roof
    draw.rectangle([680, 160, 760, 290], outline='black', width=LW)

    return img

def draw_flower():
    """Draw a simple flower."""
    img = Image.new('RGB', SIZE, 'white')
    draw = ImageDraw.Draw(img)

    # Stem
    draw.line([(512, 500), (512, 900)], fill='black', width=LINE_WIDTH)

    # Leaves
    draw.ellipse([520, 650, 680, 750], outline='black', width=LINE_WIDTH)
    draw.ellipse([344, 700, 504, 800], outline='black', width=LINE_WIDTH)

    # Center
    draw.ellipse([412, 350, 612, 550], outline='black', width=LINE_WIDTH)

    # Petals
    import math
    for i in range(6):
        angle = i * 60 * math.pi / 180
        cx = 512 + 200 * math.cos(angle)
        cy = 450 + 200 * math.sin(angle)
        draw.ellipse([cx-80, cy-80, cx+80, cy+80], outline='black', width=LINE_WIDTH)

    return img

def draw_star():
    """Draw a simple star."""
    img = Image.new('RGB', SIZE, 'white')
    draw = ImageDraw.Draw(img)

    import math
    # 5-pointed star
    points = []
    for i in range(10):
        angle = (i * 36 - 90) * math.pi / 180
        r = 400 if i % 2 == 0 else 180
        x = 512 + r * math.cos(angle)
        y = 512 + r * math.sin(angle)
        points.append((x, y))

    draw.polygon(points, outline='black', width=LINE_WIDTH)

    # Face
    draw.ellipse([420, 400, 480, 460], outline='black', width=LINE_WIDTH)
    draw.ellipse([544, 400, 604, 460], outline='black', width=LINE_WIDTH)
    draw.arc([430, 480, 594, 580], 0, 180, fill='black', width=LINE_WIDTH)

    return img

def main():
    """Generate all coloring pages."""
    os.makedirs(ASSETS_DIR, exist_ok=True)

    # Create Contents.json for the folder
    folder_contents = """{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}"""
    with open(os.path.join(ASSETS_DIR, "Contents.json"), "w") as f:
        f.write(folder_contents)

    # Generate images
    create_imageset("animal_cat", draw_cat())
    create_imageset("animal_dog", draw_dog())
    create_imageset("animal_elephant", draw_elephant())
    create_imageset("ocean_fish", draw_fish())
    create_imageset("vehicle_car", draw_car())
    create_imageset("house_cottage", draw_house())
    create_imageset("nature_flower", draw_flower())
    create_imageset("nature_star", draw_star())

    print("\nDone! Coloring pages created in:", ASSETS_DIR)

if __name__ == "__main__":
    main()
