#!/usr/bin/env python3
"""Generate coloring pages for new categories."""
import cv2
import numpy as np
from pathlib import Path

OUTPUT_DIR = Path(__file__).parent / "raw_downloads" / "new_categories"


def generate_dinosaur(size: int, variant: int) -> np.ndarray:
    """Generate simple dinosaur outlines."""
    img = np.ones((size, size), dtype=np.uint8) * 255
    center = size // 2

    if variant == 0:  # T-Rex
        # Body
        cv2.ellipse(img, (center, center + 50), (180, 120), 0, 0, 360, 0, 3)
        # Head
        cv2.ellipse(img, (center + 200, center - 50), (100, 70), 0, 0, 360, 0, 3)
        # Mouth
        cv2.line(img, (center + 280, center - 50), (center + 350, center - 30), 0, 3)
        cv2.line(img, (center + 280, center - 50), (center + 350, center - 70), 0, 3)
        # Eye
        cv2.circle(img, (center + 230, center - 70), 15, 0, 2)
        # Legs
        cv2.line(img, (center - 50, center + 150), (center - 50, center + 320), 0, 3)
        cv2.line(img, (center + 50, center + 150), (center + 50, center + 320), 0, 3)
        # Tiny arms
        cv2.line(img, (center + 100, center), (center + 130, center + 60), 0, 2)
        # Tail
        pts = np.array([[center - 150, center + 50], [center - 280, center], [center - 350, center + 30]], np.int32)
        cv2.polylines(img, [pts], False, 0, 3)

    elif variant == 1:  # Triceratops
        # Body
        cv2.ellipse(img, (center - 50, center + 50), (200, 130), 0, 0, 360, 0, 3)
        # Head shield
        cv2.ellipse(img, (center + 180, center - 50), (120, 100), 0, 0, 360, 0, 3)
        # Horns
        cv2.line(img, (center + 200, center - 130), (center + 220, center - 220), 0, 3)
        cv2.line(img, (center + 280, center - 80), (center + 360, center - 120), 0, 3)
        cv2.line(img, (center + 280, center - 20), (center + 360, center + 20), 0, 3)
        # Eye
        cv2.circle(img, (center + 230, center - 50), 15, 0, 2)
        # Legs
        cv2.rectangle(img, (center - 180, center + 150), (center - 130, center + 320), 0, 3)
        cv2.rectangle(img, (center - 30, center + 150), (center + 20, center + 320), 0, 3)
        # Tail
        pts = np.array([[center - 220, center + 50], [center - 350, center + 100]], np.int32)
        cv2.polylines(img, [pts], False, 0, 3)

    else:  # Stegosaurus
        # Body
        cv2.ellipse(img, (center, center + 80), (200, 100), 0, 0, 360, 0, 3)
        # Head
        cv2.ellipse(img, (center + 250, center + 50), (60, 40), 0, 0, 360, 0, 3)
        # Eye
        cv2.circle(img, (center + 270, center + 40), 10, 0, 2)
        # Plates on back
        for i, x_off in enumerate([-120, -60, 0, 60, 120]):
            h = 60 + abs(x_off) // 3
            pts = np.array([
                [center + x_off - 15, center],
                [center + x_off, center - h],
                [center + x_off + 15, center]
            ], np.int32)
            cv2.polylines(img, [pts], True, 0, 2)
        # Legs
        cv2.rectangle(img, (center - 120, center + 150), (center - 80, center + 300), 0, 3)
        cv2.rectangle(img, (center + 80, center + 150), (center + 120, center + 300), 0, 3)
        # Tail with spikes
        cv2.line(img, (center - 180, center + 80), (center - 350, center + 50), 0, 3)
        # Tail spikes
        cv2.line(img, (center - 300, center + 50), (center - 330, center - 20), 0, 2)
        cv2.line(img, (center - 340, center + 50), (center - 380, center), 0, 2)

    return img


def generate_space(size: int, variant: int) -> np.ndarray:
    """Generate space-themed outlines."""
    img = np.ones((size, size), dtype=np.uint8) * 255
    center = size // 2

    if variant == 0:  # Rocket
        # Body
        cv2.rectangle(img, (center - 60, center - 200), (center + 60, center + 200), 0, 3)
        # Nose cone
        pts = np.array([[center - 60, center - 200], [center, center - 350], [center + 60, center - 200]], np.int32)
        cv2.polylines(img, [pts], True, 0, 3)
        # Fins
        pts1 = np.array([[center - 60, center + 200], [center - 150, center + 300], [center - 60, center + 100]], np.int32)
        pts2 = np.array([[center + 60, center + 200], [center + 150, center + 300], [center + 60, center + 100]], np.int32)
        cv2.polylines(img, [pts1, pts2], True, 0, 3)
        # Window
        cv2.circle(img, (center, center - 80), 40, 0, 2)
        # Flames
        pts = np.array([[center - 40, center + 200], [center, center + 320], [center + 40, center + 200]], np.int32)
        cv2.polylines(img, [pts], True, 0, 2)

    elif variant == 1:  # Astronaut
        # Helmet
        cv2.circle(img, (center, center - 150), 100, 0, 3)
        # Visor
        cv2.ellipse(img, (center, center - 150), (70, 50), 0, 0, 360, 0, 2)
        # Body/suit
        cv2.rectangle(img, (center - 80, center - 50), (center + 80, center + 150), 0, 3)
        # Arms
        cv2.rectangle(img, (center - 160, center - 30), (center - 80, center + 30), 0, 3)
        cv2.rectangle(img, (center + 80, center - 30), (center + 160, center + 30), 0, 3)
        # Legs
        cv2.rectangle(img, (center - 60, center + 150), (center - 20, center + 320), 0, 3)
        cv2.rectangle(img, (center + 20, center + 150), (center + 60, center + 320), 0, 3)
        # Backpack
        cv2.rectangle(img, (center - 100, center - 30), (center - 80, center + 100), 0, 2)

    else:  # Planet with rings
        # Planet
        cv2.circle(img, (center, center), 150, 0, 3)
        # Rings
        cv2.ellipse(img, (center, center), (280, 80), 30, 0, 360, 0, 2)
        cv2.ellipse(img, (center, center), (320, 100), 30, 0, 360, 0, 2)
        # Crater details
        cv2.circle(img, (center - 50, center - 40), 30, 0, 1)
        cv2.circle(img, (center + 60, center + 30), 25, 0, 1)
        cv2.circle(img, (center - 20, center + 60), 20, 0, 1)

    return img


def generate_food(size: int, variant: int) -> np.ndarray:
    """Generate food-themed outlines."""
    img = np.ones((size, size), dtype=np.uint8) * 255
    center = size // 2

    if variant == 0:  # Cupcake
        # Cup base
        pts = np.array([
            [center - 100, center],
            [center - 80, center + 150],
            [center + 80, center + 150],
            [center + 100, center]
        ], np.int32)
        cv2.polylines(img, [pts], True, 0, 3)
        # Frosting swirl
        cv2.ellipse(img, (center, center - 50), (110, 80), 0, 0, 360, 0, 3)
        cv2.ellipse(img, (center, center - 100), (80, 60), 0, 0, 360, 0, 2)
        cv2.ellipse(img, (center, center - 140), (50, 40), 0, 0, 360, 0, 2)
        # Cherry on top
        cv2.circle(img, (center, center - 180), 25, 0, 2)
        # Cup lines
        for x in range(center - 80, center + 80, 20):
            cv2.line(img, (x, center), (x - 5, center + 150), 0, 1)

    elif variant == 1:  # Ice cream cone
        # Cone
        pts = np.array([
            [center - 80, center],
            [center, center + 250],
            [center + 80, center]
        ], np.int32)
        cv2.polylines(img, [pts], True, 0, 3)
        # Cone pattern
        for i in range(-60, 61, 20):
            cv2.line(img, (center + i, center + 50), (center, center + 230), 0, 1)
        # Ice cream scoops
        cv2.circle(img, (center, center - 50), 90, 0, 3)
        cv2.circle(img, (center - 60, center - 130), 70, 0, 3)
        cv2.circle(img, (center + 60, center - 130), 70, 0, 3)
        # Cherry
        cv2.circle(img, (center, center - 200), 25, 0, 2)

    else:  # Pizza slice
        # Triangle shape
        pts = np.array([
            [center, center - 200],
            [center - 180, center + 200],
            [center + 180, center + 200]
        ], np.int32)
        cv2.polylines(img, [pts], True, 0, 3)
        # Crust
        cv2.line(img, (center - 160, center + 180), (center + 160, center + 180), 0, 3)
        # Pepperoni
        cv2.circle(img, (center, center), 35, 0, 2)
        cv2.circle(img, (center - 70, center + 80), 30, 0, 2)
        cv2.circle(img, (center + 70, center + 80), 30, 0, 2)
        cv2.circle(img, (center - 30, center - 80), 25, 0, 2)
        cv2.circle(img, (center + 30, center - 80), 25, 0, 2)

    return img


def generate_robot(size: int, variant: int) -> np.ndarray:
    """Generate robot outlines."""
    img = np.ones((size, size), dtype=np.uint8) * 255
    center = size // 2

    # Head
    cv2.rectangle(img, (center - 80, center - 280), (center + 80, center - 120), 0, 3)
    # Eyes
    cv2.circle(img, (center - 40, center - 220), 25, 0, 2)
    cv2.circle(img, (center + 40, center - 220), 25, 0, 2)
    # Antenna
    cv2.line(img, (center, center - 280), (center, center - 350), 0, 2)
    cv2.circle(img, (center, center - 360), 15, 0, 2)

    # Body
    cv2.rectangle(img, (center - 100, center - 120), (center + 100, center + 120), 0, 3)
    # Buttons/details
    cv2.circle(img, (center, center - 50), 20, 0, 2)
    cv2.circle(img, (center, center + 20), 20, 0, 2)
    cv2.rectangle(img, (center - 60, center + 60), (center + 60, center + 100), 0, 2)

    # Arms
    cv2.rectangle(img, (center - 180, center - 100), (center - 100, center - 40), 0, 3)
    cv2.rectangle(img, (center + 100, center - 100), (center + 180, center - 40), 0, 3)
    # Claws
    cv2.line(img, (center - 180, center - 70), (center - 220, center - 50), 0, 2)
    cv2.line(img, (center - 180, center - 70), (center - 220, center - 90), 0, 2)
    cv2.line(img, (center + 180, center - 70), (center + 220, center - 50), 0, 2)
    cv2.line(img, (center + 180, center - 70), (center + 220, center - 90), 0, 2)

    # Legs
    cv2.rectangle(img, (center - 70, center + 120), (center - 30, center + 300), 0, 3)
    cv2.rectangle(img, (center + 30, center + 120), (center + 70, center + 300), 0, 3)
    # Feet
    cv2.rectangle(img, (center - 90, center + 280), (center - 10, center + 320), 0, 3)
    cv2.rectangle(img, (center + 10, center + 280), (center + 90, center + 320), 0, 3)

    return img


def generate_fantasy(size: int, variant: int) -> np.ndarray:
    """Generate fantasy-themed outlines."""
    img = np.ones((size, size), dtype=np.uint8) * 255
    center = size // 2

    if variant == 0:  # Unicorn
        # Body
        cv2.ellipse(img, (center - 50, center + 50), (180, 100), 0, 0, 360, 0, 3)
        # Head
        cv2.ellipse(img, (center + 150, center - 50), (80, 60), 0, 0, 360, 0, 3)
        # Horn
        pts = np.array([[center + 150, center - 100], [center + 170, center - 220], [center + 190, center - 100]], np.int32)
        cv2.polylines(img, [pts], True, 0, 3)
        # Eye
        cv2.circle(img, (center + 170, center - 60), 15, 0, 2)
        # Mane
        for i in range(5):
            y = center - 80 + i * 30
            cv2.ellipse(img, (center + 80, y), (40, 20), 0, 0, 360, 0, 2)
        # Legs
        cv2.line(img, (center - 120, center + 130), (center - 120, center + 300), 0, 3)
        cv2.line(img, (center - 40, center + 130), (center - 40, center + 300), 0, 3)
        cv2.line(img, (center + 40, center + 130), (center + 40, center + 300), 0, 3)
        cv2.line(img, (center + 120, center + 130), (center + 120, center + 300), 0, 3)
        # Tail
        pts = np.array([[center - 200, center + 50], [center - 280, center + 100], [center - 300, center + 50], [center - 280, center]], np.int32)
        cv2.polylines(img, [pts], False, 0, 2)

    elif variant == 1:  # Dragon
        # Body
        cv2.ellipse(img, (center, center + 50), (180, 100), 0, 0, 360, 0, 3)
        # Head
        cv2.ellipse(img, (center + 200, center - 30), (100, 70), 0, 0, 360, 0, 3)
        # Eye
        cv2.circle(img, (center + 230, center - 50), 20, 0, 2)
        # Wings
        pts1 = np.array([[center - 50, center], [center - 150, center - 200], [center - 50, center - 150], [center + 50, center - 200], [center + 50, center]], np.int32)
        cv2.polylines(img, [pts1], True, 0, 3)
        # Legs
        cv2.line(img, (center - 80, center + 130), (center - 100, center + 280), 0, 3)
        cv2.line(img, (center + 80, center + 130), (center + 100, center + 280), 0, 3)
        # Tail
        pts = np.array([[center - 160, center + 50], [center - 300, center + 80], [center - 350, center + 30]], np.int32)
        cv2.polylines(img, [pts], False, 0, 3)
        # Spikes
        for x in range(center - 100, center + 50, 40):
            cv2.line(img, (x, center - 20), (x, center - 60), 0, 2)

    else:  # Castle
        # Main tower
        cv2.rectangle(img, (center - 60, center - 100), (center + 60, center + 200), 0, 3)
        # Battlements
        for x in range(center - 60, center + 61, 30):
            cv2.rectangle(img, (x - 10, center - 140), (x + 10, center - 100), 0, 2)
        # Side towers
        cv2.rectangle(img, (center - 180, center - 50), (center - 100, center + 200), 0, 3)
        cv2.rectangle(img, (center + 100, center - 50), (center + 180, center + 200), 0, 3)
        # Tower roofs
        pts1 = np.array([[center - 180, center - 50], [center - 140, center - 150], [center - 100, center - 50]], np.int32)
        pts2 = np.array([[center + 100, center - 50], [center + 140, center - 150], [center + 180, center - 50]], np.int32)
        cv2.polylines(img, [pts1, pts2], True, 0, 3)
        # Door
        cv2.rectangle(img, (center - 30, center + 100), (center + 30, center + 200), 0, 2)
        # Windows
        cv2.rectangle(img, (center - 30, center - 50), (center + 30, center), 0, 2)
        cv2.rectangle(img, (center - 150, center), (center - 130, center + 40), 0, 2)
        cv2.rectangle(img, (center + 130, center), (center + 150, center + 40), 0, 2)

    return img


def generate_underwater(size: int, variant: int) -> np.ndarray:
    """Generate underwater-themed outlines."""
    img = np.ones((size, size), dtype=np.uint8) * 255
    center = size // 2

    if variant == 0:  # Octopus
        # Head
        cv2.ellipse(img, (center, center - 100), (120, 100), 0, 0, 360, 0, 3)
        # Eyes
        cv2.circle(img, (center - 50, center - 120), 25, 0, 2)
        cv2.circle(img, (center + 50, center - 120), 25, 0, 2)
        # Tentacles (8)
        angles = [-150, -120, -60, -30, 30, 60, 120, 150]
        for angle in angles:
            rad = np.radians(angle)
            x1 = int(center + 80 * np.cos(rad))
            y1 = center
            x2 = int(center + 200 * np.cos(rad))
            y2 = center + 200
            pts = np.array([[x1, y1], [(x1 + x2) // 2, (y1 + y2) // 2 + 30], [x2, y2]], np.int32)
            cv2.polylines(img, [pts], False, 0, 3)
            # Suction cups
            for t in [0.3, 0.6, 0.9]:
                cx = int(x1 + t * (x2 - x1))
                cy = int(y1 + t * (y2 - y1) + 30 * t)
                cv2.circle(img, (cx, cy), 8, 0, 1)

    elif variant == 1:  # Seahorse
        # Body curve
        pts = []
        for t in np.linspace(0, 2 * np.pi, 50):
            r = 80 + 40 * np.sin(2 * t)
            x = int(center + r * np.cos(t) * 0.5)
            y = int(center + t * 60 - 150)
            pts.append([x, y])
        cv2.polylines(img, [np.array(pts, np.int32)], False, 0, 3)
        # Head
        cv2.circle(img, (center + 60, center - 150), 50, 0, 3)
        # Snout
        cv2.line(img, (center + 100, center - 150), (center + 180, center - 140), 0, 3)
        # Eye
        cv2.circle(img, (center + 70, center - 160), 15, 0, 2)
        # Dorsal fin
        for i in range(5):
            y = center - 50 + i * 40
            cv2.line(img, (center - 30, y), (center - 80, y - 20), 0, 2)
        # Curled tail
        cv2.ellipse(img, (center, center + 200), (40, 40), 0, 0, 270, 0, 3)

    else:  # Turtle
        # Shell
        cv2.ellipse(img, (center, center), (180, 120), 0, 0, 360, 0, 3)
        # Shell pattern
        cv2.ellipse(img, (center, center), (120, 80), 0, 0, 360, 0, 2)
        cv2.ellipse(img, (center, center), (60, 40), 0, 0, 360, 0, 2)
        # Shell segments
        for angle in range(0, 360, 45):
            rad = np.radians(angle)
            x1 = int(center + 60 * np.cos(rad))
            y1 = int(center + 40 * np.sin(rad))
            x2 = int(center + 180 * np.cos(rad))
            y2 = int(center + 120 * np.sin(rad))
            cv2.line(img, (x1, y1), (x2, y2), 0, 2)
        # Head
        cv2.ellipse(img, (center + 200, center), (50, 40), 0, 0, 360, 0, 3)
        # Eye
        cv2.circle(img, (center + 220, center - 10), 10, 0, 2)
        # Flippers
        cv2.ellipse(img, (center - 160, center - 80), (60, 30), -45, 0, 360, 0, 3)
        cv2.ellipse(img, (center - 160, center + 80), (60, 30), 45, 0, 360, 0, 3)
        cv2.ellipse(img, (center + 100, center - 100), (50, 25), -30, 0, 360, 0, 3)
        cv2.ellipse(img, (center + 100, center + 100), (50, 25), 30, 0, 360, 0, 3)

    return img


def main():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    size = 1024

    generators = [
        ("dino_trex", lambda: generate_dinosaur(size, 0)),
        ("dino_triceratops", lambda: generate_dinosaur(size, 1)),
        ("dino_stegosaurus", lambda: generate_dinosaur(size, 2)),
        ("space_rocket", lambda: generate_space(size, 0)),
        ("space_astronaut", lambda: generate_space(size, 1)),
        ("space_planet", lambda: generate_space(size, 2)),
        ("food_cupcake", lambda: generate_food(size, 0)),
        ("food_icecream", lambda: generate_food(size, 1)),
        ("food_pizza", lambda: generate_food(size, 2)),
        ("robot_01", lambda: generate_robot(size, 0)),
        ("robot_02", lambda: generate_robot(size, 1)),
        ("robot_03", lambda: generate_robot(size, 2)),
        ("fantasy_unicorn", lambda: generate_fantasy(size, 0)),
        ("fantasy_dragon", lambda: generate_fantasy(size, 1)),
        ("fantasy_castle", lambda: generate_fantasy(size, 2)),
        ("underwater_octopus", lambda: generate_underwater(size, 0)),
        ("underwater_seahorse", lambda: generate_underwater(size, 1)),
        ("underwater_turtle", lambda: generate_underwater(size, 2)),
    ]

    print(f"Generating {len(generators)} coloring pages...")

    for name, gen_func in generators:
        save_path = OUTPUT_DIR / f"{name}.png"
        print(f"  Generating: {name}...")

        try:
            img = gen_func()
            cv2.imwrite(str(save_path), img)
            print(f"    Created: {save_path}")
        except Exception as e:
            print(f"    Error: {e}")

    print("\nDone!")


if __name__ == "__main__":
    main()
