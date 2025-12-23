"""
Download coloring pages from free sources without API keys.
Uses public domain and CC0 licensed images.
"""
import time
import requests
from pathlib import Path
from typing import List, Dict
from urllib.parse import urlparse
import re
import cv2
import numpy as np

from ..config import RAW_DOWNLOADS_DIR
from ..utils import (
    validate_image_size,
    is_line_art,
    is_duplicate,
    cleanup_filename
)


# Curated list of free coloring page URLs (public domain / CC0)
FREE_COLORING_PAGES = {
    "mandalas": [
        # Public domain mandala patterns
        ("https://upload.wikimedia.org/wikipedia/commons/thumb/8/8d/Mandala_1.svg/1024px-Mandala_1.svg.png", "mandala_wiki_1"),
        ("https://upload.wikimedia.org/wikipedia/commons/thumb/6/6d/Mandala_2.svg/1024px-Mandala_2.svg.png", "mandala_wiki_2"),
        ("https://upload.wikimedia.org/wikipedia/commons/thumb/0/0a/Mandala_3.svg/1024px-Mandala_3.svg.png", "mandala_wiki_3"),
        ("https://upload.wikimedia.org/wikipedia/commons/thumb/5/5c/Mandala-5.svg/1024px-Mandala-5.svg.png", "mandala_wiki_5"),
        ("https://upload.wikimedia.org/wikipedia/commons/thumb/9/97/Mandala-6.svg/1024px-Mandala-6.svg.png", "mandala_wiki_6"),
    ],
    "animals": [
        # Simple animal outlines from Wikipedia commons
        ("https://upload.wikimedia.org/wikipedia/commons/thumb/3/3a/Cat03.jpg/1024px-Cat03.jpg", "animal_cat"),
        ("https://upload.wikimedia.org/wikipedia/commons/thumb/2/26/YellowLabradorLooking_new.jpg/1024px-YellowLabradorLooking_new.jpg", "animal_dog"),
    ],
    "nature": [
        # Botanical illustrations (public domain)
        ("https://upload.wikimedia.org/wikipedia/commons/thumb/4/41/Sunflower_from_Silesia.jpg/800px-Sunflower_from_Silesia.jpg", "nature_sunflower"),
    ],
    "fantasy": [
        # Fantasy line art
    ]
}


class FreeSourceDownloader:
    """Download from free/public domain sources."""

    def __init__(self):
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'ColoringAppDownloader/1.0 (Educational Use)'
        })
        self.downloaded_hashes = set()

    def download_image(self, url: str, save_path: Path) -> bool:
        """Download a single image."""
        try:
            response = self.session.get(url, timeout=60, stream=True)
            response.raise_for_status()

            save_path.parent.mkdir(parents=True, exist_ok=True)

            with open(save_path, 'wb') as f:
                for chunk in response.iter_content(chunk_size=8192):
                    f.write(chunk)

            return True

        except requests.RequestException as e:
            print(f"    Download error: {e}")
            return False

    def download_from_url_list(
        self,
        category: str,
        urls: List[tuple],
        output_dir: Path = None
    ) -> List[Dict]:
        """Download images from URL list."""
        if output_dir is None:
            output_dir = RAW_DOWNLOADS_DIR / category

        output_dir.mkdir(parents=True, exist_ok=True)

        downloaded = []

        print(f"\n  Downloading {category} from curated URLs...")

        for url, name in urls:
            # Determine extension
            parsed = urlparse(url)
            ext = Path(parsed.path).suffix or '.png'
            if ext not in ['.png', '.jpg', '.jpeg', '.svg']:
                ext = '.png'

            save_path = output_dir / f"{name}{ext}"

            if save_path.exists():
                print(f"    Skipping (exists): {name}")
                continue

            print(f"    Downloading: {name}...")
            time.sleep(0.5)  # Be polite

            if self.download_image(url, save_path):
                # Validate
                if validate_image_size(save_path):
                    downloaded.append({
                        "path": str(save_path),
                        "source": "free_curated",
                        "url": url,
                        "category": category
                    })
                    print(f"      ✓ Saved")
                else:
                    print(f"      ✗ Too small")
                    save_path.unlink()

        return downloaded


def generate_simple_coloring_pages(output_dir: Path = None, count: int = 20) -> List[Dict]:
    """
    Generate simple coloring pages programmatically.
    Creates clean line art suitable for the coloring app.
    """
    if output_dir is None:
        output_dir = RAW_DOWNLOADS_DIR / "generated"

    output_dir.mkdir(parents=True, exist_ok=True)

    generated = []
    size = 1024

    print(f"\n  Generating {count} simple coloring pages...")

    # Category generators
    generators = {
        "mandala": generate_mandala,
        "geometric": generate_geometric,
        "animal_simple": generate_simple_animal,
        "flower": generate_flower,
        "abstract": generate_abstract
    }

    pages_per_type = count // len(generators)

    for gen_name, gen_func in generators.items():
        for i in range(pages_per_type):
            name = f"{gen_name}_{i+1:02d}"
            save_path = output_dir / f"{name}.png"

            if save_path.exists():
                continue

            print(f"    Generating: {name}...")

            try:
                img = gen_func(size, seed=i)
                cv2.imwrite(str(save_path), img)

                generated.append({
                    "path": str(save_path),
                    "source": "generated",
                    "category": gen_name,
                    "name": name
                })
                print(f"      ✓ Created")

            except Exception as e:
                print(f"      ✗ Error: {e}")

    return generated


def generate_mandala(size: int, seed: int = 0) -> np.ndarray:
    """Generate a mandala-style pattern."""
    np.random.seed(seed)

    img = np.ones((size, size), dtype=np.uint8) * 255
    center = size // 2

    # Draw concentric circles
    num_rings = np.random.randint(4, 8)
    for r in range(1, num_rings + 1):
        radius = int(center * r / (num_rings + 1))
        cv2.circle(img, (center, center), radius, 0, 2)

    # Draw radial lines
    num_lines = np.random.choice([6, 8, 12, 16])
    for i in range(num_lines):
        angle = 2 * np.pi * i / num_lines
        x2 = int(center + center * 0.9 * np.cos(angle))
        y2 = int(center + center * 0.9 * np.sin(angle))
        cv2.line(img, (center, center), (x2, y2), 0, 2)

    # Add decorative elements
    for r in range(2, num_rings):
        radius = int(center * r / (num_rings + 1))
        for i in range(num_lines):
            angle = 2 * np.pi * i / num_lines
            x = int(center + radius * np.cos(angle))
            y = int(center + radius * np.sin(angle))

            shape = np.random.choice(['circle', 'diamond', 'petal'])
            if shape == 'circle':
                cv2.circle(img, (x, y), 15, 0, 2)
            elif shape == 'diamond':
                pts = np.array([
                    [x, y - 12], [x + 8, y], [x, y + 12], [x - 8, y]
                ], np.int32)
                cv2.polylines(img, [pts], True, 0, 2)
            else:
                cv2.ellipse(img, (x, y), (20, 10), np.degrees(angle), 0, 360, 0, 2)

    return img


def generate_geometric(size: int, seed: int = 0) -> np.ndarray:
    """Generate geometric patterns."""
    np.random.seed(seed)

    img = np.ones((size, size), dtype=np.uint8) * 255
    center = size // 2

    # Grid of shapes
    grid_size = np.random.choice([4, 5, 6])
    cell_size = size // grid_size

    for row in range(grid_size):
        for col in range(grid_size):
            cx = col * cell_size + cell_size // 2
            cy = row * cell_size + cell_size // 2
            r = cell_size // 3

            shape = np.random.choice(['circle', 'square', 'triangle', 'hexagon'])

            if shape == 'circle':
                cv2.circle(img, (cx, cy), r, 0, 2)
            elif shape == 'square':
                cv2.rectangle(img, (cx - r, cy - r), (cx + r, cy + r), 0, 2)
            elif shape == 'triangle':
                pts = np.array([
                    [cx, cy - r],
                    [cx - r, cy + r],
                    [cx + r, cy + r]
                ], np.int32)
                cv2.polylines(img, [pts], True, 0, 2)
            else:  # hexagon
                pts = []
                for i in range(6):
                    angle = np.pi / 3 * i - np.pi / 6
                    pts.append([
                        int(cx + r * np.cos(angle)),
                        int(cy + r * np.sin(angle))
                    ])
                cv2.polylines(img, [np.array(pts, np.int32)], True, 0, 2)

    # Border
    cv2.rectangle(img, (20, 20), (size - 20, size - 20), 0, 3)

    return img


def generate_simple_animal(size: int, seed: int = 0) -> np.ndarray:
    """Generate simple animal outlines."""
    np.random.seed(seed)

    img = np.ones((size, size), dtype=np.uint8) * 255
    center = size // 2

    animal = seed % 5

    if animal == 0:  # Cat
        # Head
        cv2.circle(img, (center, center - 100), 150, 0, 3)
        # Ears
        pts1 = np.array([[center - 120, center - 200], [center - 80, center - 300], [center - 40, center - 200]], np.int32)
        pts2 = np.array([[center + 120, center - 200], [center + 80, center - 300], [center + 40, center - 200]], np.int32)
        cv2.polylines(img, [pts1, pts2], True, 0, 3)
        # Eyes
        cv2.circle(img, (center - 60, center - 120), 25, 0, 2)
        cv2.circle(img, (center + 60, center - 120), 25, 0, 2)
        # Nose
        pts = np.array([[center, center - 50], [center - 15, center - 30], [center + 15, center - 30]], np.int32)
        cv2.polylines(img, [pts], True, 0, 2)
        # Body
        cv2.ellipse(img, (center, center + 200), (120, 180), 0, 0, 360, 0, 3)

    elif animal == 1:  # Dog
        # Head
        cv2.ellipse(img, (center, center - 80), (140, 120), 0, 0, 360, 0, 3)
        # Ears
        cv2.ellipse(img, (center - 130, center - 100), (40, 80), -20, 0, 360, 0, 3)
        cv2.ellipse(img, (center + 130, center - 100), (40, 80), 20, 0, 360, 0, 3)
        # Eyes
        cv2.circle(img, (center - 50, center - 100), 20, 0, 2)
        cv2.circle(img, (center + 50, center - 100), 20, 0, 2)
        # Nose
        cv2.ellipse(img, (center, center - 30), (25, 20), 0, 0, 360, 0, 2)
        # Body
        cv2.ellipse(img, (center, center + 180), (150, 200), 0, 0, 360, 0, 3)

    elif animal == 2:  # Fish
        # Body
        cv2.ellipse(img, (center, center), (200, 100), 0, 0, 360, 0, 3)
        # Tail
        pts = np.array([[center + 180, center], [center + 280, center - 80], [center + 280, center + 80]], np.int32)
        cv2.polylines(img, [pts], True, 0, 3)
        # Eye
        cv2.circle(img, (center - 80, center - 20), 25, 0, 2)
        # Fins
        pts = np.array([[center - 50, center - 80], [center, center - 150], [center + 50, center - 80]], np.int32)
        cv2.polylines(img, [pts], True, 0, 2)
        # Scales pattern
        for x in range(-100, 100, 40):
            for y in range(-40, 40, 30):
                cv2.ellipse(img, (center + x, center + y), (15, 10), 0, 0, 180, 0, 1)

    elif animal == 3:  # Butterfly
        # Body
        cv2.ellipse(img, (center, center), (15, 100), 0, 0, 360, 0, 3)
        # Wings
        cv2.ellipse(img, (center - 120, center - 50), (100, 80), -30, 0, 360, 0, 3)
        cv2.ellipse(img, (center + 120, center - 50), (100, 80), 30, 0, 360, 0, 3)
        cv2.ellipse(img, (center - 100, center + 70), (80, 60), -20, 0, 360, 0, 3)
        cv2.ellipse(img, (center + 100, center + 70), (80, 60), 20, 0, 360, 0, 3)
        # Antennae
        cv2.line(img, (center - 10, center - 100), (center - 50, center - 180), 0, 2)
        cv2.line(img, (center + 10, center - 100), (center + 50, center - 180), 0, 2)
        cv2.circle(img, (center - 50, center - 180), 8, 0, 2)
        cv2.circle(img, (center + 50, center - 180), 8, 0, 2)

    else:  # Bird
        # Body
        cv2.ellipse(img, (center, center), (100, 70), 0, 0, 360, 0, 3)
        # Head
        cv2.circle(img, (center + 120, center - 30), 50, 0, 3)
        # Beak
        pts = np.array([[center + 160, center - 30], [center + 220, center - 20], [center + 160, center - 10]], np.int32)
        cv2.polylines(img, [pts], True, 0, 2)
        # Eye
        cv2.circle(img, (center + 130, center - 40), 10, 0, 2)
        # Wing
        cv2.ellipse(img, (center - 20, center), (80, 50), 0, 180, 360, 0, 3)
        # Tail
        pts = np.array([[center - 100, center], [center - 180, center - 40], [center - 200, center], [center - 180, center + 40]], np.int32)
        cv2.polylines(img, [pts], True, 0, 3)
        # Legs
        cv2.line(img, (center + 30, center + 70), (center + 30, center + 150), 0, 2)
        cv2.line(img, (center - 30, center + 70), (center - 30, center + 150), 0, 2)

    return img


def generate_flower(size: int, seed: int = 0) -> np.ndarray:
    """Generate flower patterns."""
    np.random.seed(seed)

    img = np.ones((size, size), dtype=np.uint8) * 255
    center = size // 2

    # Center circle
    cv2.circle(img, (center, center), 60, 0, 3)

    # Petals
    num_petals = np.random.choice([5, 6, 8, 10])
    petal_len = np.random.randint(150, 250)

    for i in range(num_petals):
        angle = 2 * np.pi * i / num_petals
        x = int(center + petal_len * np.cos(angle))
        y = int(center + petal_len * np.sin(angle))

        # Petal as ellipse
        cv2.ellipse(img, ((center + x) // 2, (center + y) // 2),
                    (petal_len // 2 - 20, 40),
                    np.degrees(angle), 0, 360, 0, 2)

    # Stem
    cv2.line(img, (center, center + 60), (center, size - 100), 0, 3)

    # Leaves
    cv2.ellipse(img, (center - 60, center + 250), (50, 25), -45, 0, 360, 0, 2)
    cv2.ellipse(img, (center + 60, center + 350), (50, 25), 45, 0, 360, 0, 2)

    return img


def generate_abstract(size: int, seed: int = 0) -> np.ndarray:
    """Generate abstract patterns."""
    np.random.seed(seed)

    img = np.ones((size, size), dtype=np.uint8) * 255

    # Random curves
    num_curves = np.random.randint(5, 10)
    for _ in range(num_curves):
        pts = []
        num_points = np.random.randint(3, 6)
        for _ in range(num_points):
            pts.append([
                np.random.randint(100, size - 100),
                np.random.randint(100, size - 100)
            ])
        pts = np.array(pts, np.int32)
        cv2.polylines(img, [pts], False, 0, 2)

    # Random circles
    num_circles = np.random.randint(5, 12)
    for _ in range(num_circles):
        cx = np.random.randint(100, size - 100)
        cy = np.random.randint(100, size - 100)
        r = np.random.randint(30, 100)
        cv2.circle(img, (cx, cy), r, 0, 2)

    # Random spirals
    for _ in range(2):
        cx = np.random.randint(200, size - 200)
        cy = np.random.randint(200, size - 200)
        for t in np.linspace(0, 4 * np.pi, 100):
            r = 10 + t * 15
            x = int(cx + r * np.cos(t))
            y = int(cy + r * np.sin(t))
            if 0 <= x < size and 0 <= y < size:
                cv2.circle(img, (x, y), 1, 0, -1)

    return img
