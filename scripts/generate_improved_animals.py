#!/usr/bin/env python3
"""Generate improved, kid-friendly animal coloring pages."""
import cv2
import numpy as np
from pathlib import Path

OUTPUT_DIR = Path(__file__).parent / "raw_downloads" / "improved_animals"


def draw_smooth_curve(img, points, color=0, thickness=3):
    """Draw a smooth curve through points using bezier-like interpolation."""
    points = np.array(points, dtype=np.int32)
    cv2.polylines(img, [points], False, color, thickness, cv2.LINE_AA)


def generate_cute_cat(size: int) -> np.ndarray:
    """Generate a cute, cartoon-style cat face with body."""
    img = np.ones((size, size), dtype=np.uint8) * 255
    cx, cy = size // 2, size // 2

    # Body (large oval)
    cv2.ellipse(img, (cx, cy + 120), (160, 200), 0, 0, 360, 0, 3)

    # Head (large circle)
    cv2.circle(img, (cx, cy - 100), 150, 0, 3)

    # Ears (triangular)
    # Left ear
    pts_left = np.array([[cx - 130, cy - 180], [cx - 80, cy - 320], [cx - 30, cy - 180]], np.int32)
    cv2.fillPoly(img, [pts_left], 255)
    cv2.polylines(img, [pts_left], True, 0, 3, cv2.LINE_AA)
    # Inner ear
    pts_inner_left = np.array([[cx - 110, cy - 200], [cx - 80, cy - 280], [cx - 50, cy - 200]], np.int32)
    cv2.polylines(img, [pts_inner_left], True, 0, 2, cv2.LINE_AA)

    # Right ear
    pts_right = np.array([[cx + 130, cy - 180], [cx + 80, cy - 320], [cx + 30, cy - 180]], np.int32)
    cv2.fillPoly(img, [pts_right], 255)
    cv2.polylines(img, [pts_right], True, 0, 3, cv2.LINE_AA)
    # Inner ear
    pts_inner_right = np.array([[cx + 110, cy - 200], [cx + 80, cy - 280], [cx + 50, cy - 200]], np.int32)
    cv2.polylines(img, [pts_inner_right], True, 0, 2, cv2.LINE_AA)

    # Eyes (large, cute)
    cv2.ellipse(img, (cx - 55, cy - 120), (35, 45), 0, 0, 360, 0, 3)
    cv2.ellipse(img, (cx + 55, cy - 120), (35, 45), 0, 0, 360, 0, 3)
    # Pupils
    cv2.circle(img, (cx - 55, cy - 110), 15, 0, -1)
    cv2.circle(img, (cx + 55, cy - 110), 15, 0, -1)
    # Eye highlights
    cv2.circle(img, (cx - 60, cy - 120), 8, 255, -1)
    cv2.circle(img, (cx + 50, cy - 120), 8, 255, -1)

    # Cute nose (triangle)
    pts_nose = np.array([[cx, cy - 50], [cx - 20, cy - 20], [cx + 20, cy - 20]], np.int32)
    cv2.fillPoly(img, [pts_nose], 0)

    # Mouth (W shape)
    cv2.line(img, (cx, cy - 20), (cx, cy + 10), 0, 3)
    cv2.ellipse(img, (cx - 25, cy + 10), (25, 20), 0, 0, 180, 0, 3)
    cv2.ellipse(img, (cx + 25, cy + 10), (25, 20), 0, 0, 180, 0, 3)

    # Whiskers
    cv2.line(img, (cx - 40, cy - 10), (cx - 140, cy - 30), 0, 2)
    cv2.line(img, (cx - 40, cy + 5), (cx - 140, cy + 5), 0, 2)
    cv2.line(img, (cx - 40, cy + 20), (cx - 140, cy + 40), 0, 2)
    cv2.line(img, (cx + 40, cy - 10), (cx + 140, cy - 30), 0, 2)
    cv2.line(img, (cx + 40, cy + 5), (cx + 140, cy + 5), 0, 2)
    cv2.line(img, (cx + 40, cy + 20), (cx + 140, cy + 40), 0, 2)

    # Front paws
    cv2.ellipse(img, (cx - 80, cy + 280), (50, 35), 0, 0, 360, 0, 3)
    cv2.ellipse(img, (cx + 80, cy + 280), (50, 35), 0, 0, 360, 0, 3)
    # Paw details
    cv2.ellipse(img, (cx - 95, cy + 270), (12, 15), 0, 0, 360, 0, 2)
    cv2.ellipse(img, (cx - 75, cy + 265), (12, 15), 0, 0, 360, 0, 2)
    cv2.ellipse(img, (cx - 55, cy + 270), (12, 15), 0, 0, 360, 0, 2)
    cv2.ellipse(img, (cx + 95, cy + 270), (12, 15), 0, 0, 360, 0, 2)
    cv2.ellipse(img, (cx + 75, cy + 265), (12, 15), 0, 0, 360, 0, 2)
    cv2.ellipse(img, (cx + 55, cy + 270), (12, 15), 0, 0, 360, 0, 2)

    # Tail (curved)
    pts = []
    for t in np.linspace(0, np.pi, 30):
        x = int(cx + 180 + 60 * np.sin(t * 2))
        y = int(cy + 200 - t * 80)
        pts.append([x, y])
    cv2.polylines(img, [np.array(pts, np.int32)], False, 0, 3, cv2.LINE_AA)

    return img


def generate_cute_dog(size: int) -> np.ndarray:
    """Generate a cute, cartoon-style dog."""
    img = np.ones((size, size), dtype=np.uint8) * 255
    cx, cy = size // 2, size // 2

    # Body
    cv2.ellipse(img, (cx, cy + 100), (180, 160), 0, 0, 360, 0, 3)

    # Head (round)
    cv2.circle(img, (cx, cy - 80), 160, 0, 3)

    # Floppy ears
    cv2.ellipse(img, (cx - 150, cy - 30), (60, 120), -20, 0, 360, 0, 3)
    cv2.ellipse(img, (cx + 150, cy - 30), (60, 120), 20, 0, 360, 0, 3)

    # Muzzle (snout)
    cv2.ellipse(img, (cx, cy - 20), (80, 60), 0, 0, 360, 0, 3)

    # Eyes (big and cute)
    cv2.circle(img, (cx - 55, cy - 120), 40, 0, 3)
    cv2.circle(img, (cx + 55, cy - 120), 40, 0, 3)
    # Pupils
    cv2.circle(img, (cx - 55, cy - 115), 18, 0, -1)
    cv2.circle(img, (cx + 55, cy - 115), 18, 0, -1)
    # Highlights
    cv2.circle(img, (cx - 62, cy - 125), 8, 255, -1)
    cv2.circle(img, (cx + 48, cy - 125), 8, 255, -1)

    # Nose (big oval)
    cv2.ellipse(img, (cx, cy - 30), (30, 20), 0, 0, 360, 0, -1)

    # Mouth
    cv2.ellipse(img, (cx, cy + 15), (30, 20), 0, 0, 180, 0, 3)

    # Tongue
    cv2.ellipse(img, (cx, cy + 35), (20, 30), 0, 0, 180, 0, 3)
    cv2.line(img, (cx, cy + 35), (cx, cy + 60), 0, 2)

    # Eyebrows (expressive)
    cv2.ellipse(img, (cx - 55, cy - 170), (30, 10), -10, 0, 180, 0, 3)
    cv2.ellipse(img, (cx + 55, cy - 170), (30, 10), 10, 0, 180, 0, 3)

    # Legs
    cv2.ellipse(img, (cx - 100, cy + 230), (40, 60), 0, 0, 360, 0, 3)
    cv2.ellipse(img, (cx + 100, cy + 230), (40, 60), 0, 0, 360, 0, 3)

    # Paw details
    for offset in [-100, 100]:
        cv2.circle(img, (cx + offset - 15, cy + 275), 12, 0, 2)
        cv2.circle(img, (cx + offset, cy + 280), 12, 0, 2)
        cv2.circle(img, (cx + offset + 15, cy + 275), 12, 0, 2)

    # Tail (wagging)
    pts = []
    for t in np.linspace(0, np.pi * 0.8, 20):
        x = int(cx + 200 + 40 * np.sin(t * 3))
        y = int(cy + 100 - t * 60)
        pts.append([x, y])
    cv2.polylines(img, [np.array(pts, np.int32)], False, 0, 4, cv2.LINE_AA)

    # Collar
    cv2.ellipse(img, (cx, cy + 60), (90, 20), 0, 160, 380, 0, 4)
    # Tag
    cv2.circle(img, (cx, cy + 85), 15, 0, 2)

    return img


def generate_elephant(size: int) -> np.ndarray:
    """Generate a cute cartoon elephant."""
    img = np.ones((size, size), dtype=np.uint8) * 255
    cx, cy = size // 2, size // 2

    # Body (large oval)
    cv2.ellipse(img, (cx - 30, cy + 50), (220, 160), 0, 0, 360, 0, 3)

    # Head
    cv2.circle(img, (cx + 150, cy - 50), 140, 0, 3)

    # Big ears
    cv2.ellipse(img, (cx + 280, cy - 80), (100, 140), 10, 0, 360, 0, 3)
    # Inner ear
    cv2.ellipse(img, (cx + 280, cy - 80), (60, 100), 10, 0, 360, 0, 2)

    # Trunk (curved)
    pts = []
    for t in np.linspace(0, np.pi * 1.2, 40):
        x = int(cx + 280 + 30 * np.sin(t))
        y = int(cy - 50 + t * 80)
        pts.append([x, y])
    # Add curl at end
    for t in np.linspace(0, np.pi * 0.8, 15):
        x = int(pts[-1][0] - 30 + 40 * np.cos(t))
        y = int(pts[-1][1] + 30 * np.sin(t))
        pts.append([x, y])
    cv2.polylines(img, [np.array(pts, np.int32)], False, 0, 4, cv2.LINE_AA)
    # Trunk outline (other side)
    pts2 = []
    for t in np.linspace(0, np.pi * 1.2, 40):
        x = int(cx + 250 + 30 * np.sin(t))
        y = int(cy - 30 + t * 80)
        pts2.append([x, y])
    cv2.polylines(img, [np.array(pts2, np.int32)], False, 0, 4, cv2.LINE_AA)

    # Eyes
    cv2.circle(img, (cx + 180, cy - 80), 25, 0, 3)
    cv2.circle(img, (cx + 180, cy - 75), 10, 0, -1)
    cv2.circle(img, (cx + 175, cy - 85), 6, 255, -1)

    # Eyebrow
    cv2.ellipse(img, (cx + 180, cy - 115), (25, 8), 0, 180, 360, 0, 2)

    # Tusks
    cv2.ellipse(img, (cx + 220, cy + 50), (15, 50), -20, 0, 360, 0, 3)

    # Legs (4 chunky legs)
    cv2.ellipse(img, (cx - 150, cy + 180), (50, 80), 0, 0, 360, 0, 3)
    cv2.ellipse(img, (cx - 50, cy + 180), (50, 80), 0, 0, 360, 0, 3)
    cv2.ellipse(img, (cx + 50, cy + 180), (50, 80), 0, 0, 360, 0, 3)
    cv2.ellipse(img, (cx + 150, cy + 180), (50, 80), 0, 0, 360, 0, 3)

    # Toenails
    for leg_x in [-150, -50, 50, 150]:
        for i in range(-1, 2):
            cv2.ellipse(img, (cx + leg_x + i * 20, cy + 250), (10, 15), 0, 0, 180, 0, 2)

    # Tail
    pts = []
    for t in np.linspace(0, np.pi, 20):
        x = int(cx - 230 - 20 * np.sin(t * 2))
        y = int(cy + 50 + t * 40)
        pts.append([x, y])
    cv2.polylines(img, [np.array(pts, np.int32)], False, 0, 3, cv2.LINE_AA)
    # Tail tuft
    cv2.ellipse(img, (cx - 250, cy + 180), (15, 25), 0, 0, 360, 0, 2)

    return img


def generate_bunny(size: int) -> np.ndarray:
    """Generate a cute bunny rabbit."""
    img = np.ones((size, size), dtype=np.uint8) * 255
    cx, cy = size // 2, size // 2

    # Body
    cv2.ellipse(img, (cx, cy + 80), (140, 180), 0, 0, 360, 0, 3)

    # Head
    cv2.circle(img, (cx, cy - 120), 120, 0, 3)

    # Long ears
    cv2.ellipse(img, (cx - 60, cy - 320), (35, 120), -10, 0, 360, 0, 3)
    cv2.ellipse(img, (cx - 60, cy - 320), (20, 90), -10, 0, 360, 0, 2)
    cv2.ellipse(img, (cx + 60, cy - 320), (35, 120), 10, 0, 360, 0, 3)
    cv2.ellipse(img, (cx + 60, cy - 320), (20, 90), 10, 0, 360, 0, 2)

    # Eyes
    cv2.circle(img, (cx - 45, cy - 140), 30, 0, 3)
    cv2.circle(img, (cx + 45, cy - 140), 30, 0, 3)
    cv2.circle(img, (cx - 45, cy - 135), 12, 0, -1)
    cv2.circle(img, (cx + 45, cy - 135), 12, 0, -1)
    cv2.circle(img, (cx - 50, cy - 145), 6, 255, -1)
    cv2.circle(img, (cx + 40, cy - 145), 6, 255, -1)

    # Nose (pink oval)
    cv2.ellipse(img, (cx, cy - 80), (20, 15), 0, 0, 360, 0, -1)

    # Mouth (Y shape)
    cv2.line(img, (cx, cy - 65), (cx, cy - 40), 0, 2)
    cv2.line(img, (cx, cy - 40), (cx - 25, cy - 20), 0, 2)
    cv2.line(img, (cx, cy - 40), (cx + 25, cy - 20), 0, 2)

    # Whiskers
    cv2.line(img, (cx - 30, cy - 70), (cx - 100, cy - 90), 0, 2)
    cv2.line(img, (cx - 30, cy - 60), (cx - 100, cy - 60), 0, 2)
    cv2.line(img, (cx + 30, cy - 70), (cx + 100, cy - 90), 0, 2)
    cv2.line(img, (cx + 30, cy - 60), (cx + 100, cy - 60), 0, 2)

    # Cheeks (fluffy)
    cv2.circle(img, (cx - 80, cy - 90), 35, 0, 2)
    cv2.circle(img, (cx + 80, cy - 90), 35, 0, 2)

    # Front paws
    cv2.ellipse(img, (cx - 60, cy + 220), (35, 50), -10, 0, 360, 0, 3)
    cv2.ellipse(img, (cx + 60, cy + 220), (35, 50), 10, 0, 360, 0, 3)

    # Back feet (big bunny feet)
    cv2.ellipse(img, (cx - 100, cy + 260), (60, 30), 0, 0, 360, 0, 3)
    cv2.ellipse(img, (cx + 100, cy + 260), (60, 30), 0, 0, 360, 0, 3)
    # Paw pads
    for offset in [-100, 100]:
        cv2.ellipse(img, (cx + offset, cy + 255), (25, 15), 0, 0, 360, 0, 2)

    # Fluffy tail
    cv2.circle(img, (cx, cy + 230), 40, 0, 3)
    # Tail fluff details
    for angle in range(0, 360, 30):
        rad = np.radians(angle)
        x = int(cx + 35 * np.cos(rad))
        y = int(cy + 230 + 35 * np.sin(rad))
        cv2.circle(img, (x, y), 12, 0, 2)

    return img


def generate_bear(size: int) -> np.ndarray:
    """Generate a cute teddy bear."""
    img = np.ones((size, size), dtype=np.uint8) * 255
    cx, cy = size // 2, size // 2

    # Body
    cv2.ellipse(img, (cx, cy + 80), (160, 200), 0, 0, 360, 0, 3)

    # Head
    cv2.circle(img, (cx, cy - 120), 140, 0, 3)

    # Round ears
    cv2.circle(img, (cx - 110, cy - 220), 50, 0, 3)
    cv2.circle(img, (cx - 110, cy - 220), 30, 0, 2)
    cv2.circle(img, (cx + 110, cy - 220), 50, 0, 3)
    cv2.circle(img, (cx + 110, cy - 220), 30, 0, 2)

    # Eyes
    cv2.circle(img, (cx - 50, cy - 140), 25, 0, 3)
    cv2.circle(img, (cx + 50, cy - 140), 25, 0, 3)
    cv2.circle(img, (cx - 50, cy - 135), 10, 0, -1)
    cv2.circle(img, (cx + 50, cy - 135), 10, 0, -1)
    cv2.circle(img, (cx - 55, cy - 145), 5, 255, -1)
    cv2.circle(img, (cx + 45, cy - 145), 5, 255, -1)

    # Muzzle
    cv2.ellipse(img, (cx, cy - 70), (60, 50), 0, 0, 360, 0, 3)

    # Nose
    cv2.ellipse(img, (cx, cy - 85), (25, 18), 0, 0, 360, 0, -1)

    # Mouth
    cv2.line(img, (cx, cy - 67), (cx, cy - 45), 0, 2)
    cv2.ellipse(img, (cx - 20, cy - 40), (20, 15), 0, 0, 180, 0, 2)
    cv2.ellipse(img, (cx + 20, cy - 40), (20, 15), 0, 0, 180, 0, 2)

    # Arms
    cv2.ellipse(img, (cx - 180, cy + 30), (60, 100), 20, 0, 360, 0, 3)
    cv2.ellipse(img, (cx + 180, cy + 30), (60, 100), -20, 0, 360, 0, 3)
    # Paw pads
    cv2.ellipse(img, (cx - 210, cy + 100), (30, 25), 20, 0, 360, 0, 2)
    cv2.ellipse(img, (cx + 210, cy + 100), (30, 25), -20, 0, 360, 0, 2)

    # Legs
    cv2.ellipse(img, (cx - 80, cy + 240), (60, 50), 0, 0, 360, 0, 3)
    cv2.ellipse(img, (cx + 80, cy + 240), (60, 50), 0, 0, 360, 0, 3)
    # Foot pads
    cv2.ellipse(img, (cx - 80, cy + 250), (35, 25), 0, 0, 360, 0, 2)
    cv2.ellipse(img, (cx + 80, cy + 250), (35, 25), 0, 0, 360, 0, 2)
    # Toe pads
    for offset in [-80, 80]:
        cv2.circle(img, (cx + offset - 25, cy + 225), 10, 0, 2)
        cv2.circle(img, (cx + offset, cy + 220), 10, 0, 2)
        cv2.circle(img, (cx + offset + 25, cy + 225), 10, 0, 2)

    # Belly patch
    cv2.ellipse(img, (cx, cy + 80), (80, 100), 0, 0, 360, 0, 2)

    return img


def generate_bird(size: int) -> np.ndarray:
    """Generate a cute cartoon bird."""
    img = np.ones((size, size), dtype=np.uint8) * 255
    cx, cy = size // 2, size // 2

    # Body
    cv2.ellipse(img, (cx, cy + 50), (120, 150), 0, 0, 360, 0, 3)

    # Head
    cv2.circle(img, (cx, cy - 100), 100, 0, 3)

    # Wing (left)
    pts = np.array([
        [cx - 80, cy],
        [cx - 200, cy - 50],
        [cx - 220, cy + 20],
        [cx - 200, cy + 80],
        [cx - 150, cy + 100],
        [cx - 80, cy + 80]
    ], np.int32)
    cv2.polylines(img, [pts], True, 0, 3, cv2.LINE_AA)
    # Wing feather details
    cv2.line(img, (cx - 120, cy), (cx - 180, cy + 60), 0, 2)
    cv2.line(img, (cx - 100, cy + 20), (cx - 160, cy + 80), 0, 2)

    # Wing (right)
    pts = np.array([
        [cx + 80, cy],
        [cx + 200, cy - 50],
        [cx + 220, cy + 20],
        [cx + 200, cy + 80],
        [cx + 150, cy + 100],
        [cx + 80, cy + 80]
    ], np.int32)
    cv2.polylines(img, [pts], True, 0, 3, cv2.LINE_AA)
    cv2.line(img, (cx + 120, cy), (cx + 180, cy + 60), 0, 2)
    cv2.line(img, (cx + 100, cy + 20), (cx + 160, cy + 80), 0, 2)

    # Eyes
    cv2.circle(img, (cx - 35, cy - 110), 25, 0, 3)
    cv2.circle(img, (cx + 35, cy - 110), 25, 0, 3)
    cv2.circle(img, (cx - 35, cy - 105), 10, 0, -1)
    cv2.circle(img, (cx + 35, cy - 105), 10, 0, -1)
    cv2.circle(img, (cx - 40, cy - 115), 5, 255, -1)
    cv2.circle(img, (cx + 30, cy - 115), 5, 255, -1)

    # Beak
    pts = np.array([
        [cx - 20, cy - 70],
        [cx, cy - 20],
        [cx + 20, cy - 70]
    ], np.int32)
    cv2.polylines(img, [pts], True, 0, 3, cv2.LINE_AA)
    cv2.line(img, (cx - 15, cy - 55), (cx + 15, cy - 55), 0, 2)

    # Head tuft/crest
    pts = np.array([
        [cx - 20, cy - 180],
        [cx, cy - 250],
        [cx + 20, cy - 180]
    ], np.int32)
    cv2.polylines(img, [pts], True, 0, 3, cv2.LINE_AA)
    pts = np.array([
        [cx - 40, cy - 170],
        [cx - 30, cy - 220],
        [cx - 10, cy - 170]
    ], np.int32)
    cv2.polylines(img, [pts], True, 0, 2, cv2.LINE_AA)
    pts = np.array([
        [cx + 40, cy - 170],
        [cx + 30, cy - 220],
        [cx + 10, cy - 170]
    ], np.int32)
    cv2.polylines(img, [pts], True, 0, 2, cv2.LINE_AA)

    # Tail feathers
    for angle in [-20, 0, 20]:
        rad = np.radians(angle + 90)
        x_end = int(cx + 150 * np.cos(rad))
        y_end = int(cy + 200 + 150 * np.sin(rad))
        cv2.line(img, (cx, cy + 180), (x_end, y_end), 0, 3)

    # Feet
    cv2.line(img, (cx - 40, cy + 180), (cx - 40, cy + 250), 0, 3)
    cv2.line(img, (cx + 40, cy + 180), (cx + 40, cy + 250), 0, 3)
    # Toes
    for offset in [-40, 40]:
        cv2.line(img, (cx + offset, cy + 250), (cx + offset - 30, cy + 280), 0, 2)
        cv2.line(img, (cx + offset, cy + 250), (cx + offset, cy + 290), 0, 2)
        cv2.line(img, (cx + offset, cy + 250), (cx + offset + 30, cy + 280), 0, 2)

    # Belly marking
    cv2.ellipse(img, (cx, cy + 80), (60, 80), 0, 0, 360, 0, 2)

    return img


def generate_fox(size: int) -> np.ndarray:
    """Generate a cute cartoon fox."""
    img = np.ones((size, size), dtype=np.uint8) * 255
    cx, cy = size // 2, size // 2

    # Body
    cv2.ellipse(img, (cx, cy + 80), (140, 180), 0, 0, 360, 0, 3)

    # Head (slightly triangular)
    cv2.circle(img, (cx, cy - 100), 130, 0, 3)

    # Pointy ears
    pts_left = np.array([
        [cx - 100, cy - 180],
        [cx - 70, cy - 320],
        [cx - 20, cy - 200]
    ], np.int32)
    cv2.fillPoly(img, [pts_left], 255)
    cv2.polylines(img, [pts_left], True, 0, 3, cv2.LINE_AA)
    # Inner ear
    pts_inner = np.array([
        [cx - 85, cy - 200],
        [cx - 70, cy - 280],
        [cx - 40, cy - 210]
    ], np.int32)
    cv2.polylines(img, [pts_inner], True, 0, 2, cv2.LINE_AA)

    pts_right = np.array([
        [cx + 100, cy - 180],
        [cx + 70, cy - 320],
        [cx + 20, cy - 200]
    ], np.int32)
    cv2.fillPoly(img, [pts_right], 255)
    cv2.polylines(img, [pts_right], True, 0, 3, cv2.LINE_AA)
    pts_inner = np.array([
        [cx + 85, cy - 200],
        [cx + 70, cy - 280],
        [cx + 40, cy - 210]
    ], np.int32)
    cv2.polylines(img, [pts_inner], True, 0, 2, cv2.LINE_AA)

    # Snout (pointed)
    cv2.ellipse(img, (cx, cy - 50), (50, 40), 0, 0, 360, 0, 3)

    # Eyes (almond shaped)
    cv2.ellipse(img, (cx - 45, cy - 120), (25, 35), -10, 0, 360, 0, 3)
    cv2.ellipse(img, (cx + 45, cy - 120), (25, 35), 10, 0, 360, 0, 3)
    cv2.circle(img, (cx - 45, cy - 115), 12, 0, -1)
    cv2.circle(img, (cx + 45, cy - 115), 12, 0, -1)
    cv2.circle(img, (cx - 50, cy - 125), 5, 255, -1)
    cv2.circle(img, (cx + 40, cy - 125), 5, 255, -1)

    # Nose
    pts = np.array([
        [cx, cy - 70],
        [cx - 15, cy - 50],
        [cx + 15, cy - 50]
    ], np.int32)
    cv2.fillPoly(img, [pts], 0)

    # Mouth
    cv2.line(img, (cx, cy - 50), (cx, cy - 25), 0, 2)
    cv2.ellipse(img, (cx - 15, cy - 20), (15, 10), 0, 0, 180, 0, 2)
    cv2.ellipse(img, (cx + 15, cy - 20), (15, 10), 0, 0, 180, 0, 2)

    # Cheek markings
    cv2.ellipse(img, (cx - 80, cy - 80), (30, 20), -20, 0, 360, 0, 2)
    cv2.ellipse(img, (cx + 80, cy - 80), (30, 20), 20, 0, 360, 0, 2)

    # Chest marking
    cv2.ellipse(img, (cx, cy + 30), (60, 80), 0, 0, 360, 0, 2)

    # Front legs
    cv2.ellipse(img, (cx - 60, cy + 220), (35, 60), 0, 0, 360, 0, 3)
    cv2.ellipse(img, (cx + 60, cy + 220), (35, 60), 0, 0, 360, 0, 3)
    # Paw markings
    cv2.ellipse(img, (cx - 60, cy + 260), (25, 15), 0, 0, 360, 0, 2)
    cv2.ellipse(img, (cx + 60, cy + 260), (25, 15), 0, 0, 360, 0, 2)

    # Big fluffy tail
    pts = []
    for t in np.linspace(0, np.pi * 1.5, 40):
        r = 80 + 40 * np.sin(t * 2)
        x = int(cx + 150 + r * np.cos(t + np.pi/4))
        y = int(cy + 100 + r * np.sin(t + np.pi/4) * 0.6)
        pts.append([x, y])
    cv2.polylines(img, [np.array(pts, np.int32)], False, 0, 4, cv2.LINE_AA)
    # Tail tip
    cv2.ellipse(img, (cx + 220, cy + 50), (40, 30), 30, 0, 360, 0, 2)

    return img


def main():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    size = 1024

    generators = [
        ("animal_cat", generate_cute_cat),
        ("animal_dog", generate_cute_dog),
        ("animal_elephant", generate_elephant),
        ("animal_simple_01", generate_bunny),  # Bunny
        ("animal_simple_03", generate_bear),    # Bear
        ("animal_simple_04", generate_bird),    # Bird
        ("animal_simple_06", generate_fox),     # Fox
    ]

    print(f"Generating {len(generators)} improved animal coloring pages...")

    for name, gen_func in generators:
        save_path = OUTPUT_DIR / f"{name}.png"
        print(f"  Generating: {name}...")

        try:
            img = gen_func(size)
            cv2.imwrite(str(save_path), img)
            print(f"    Created: {save_path}")
        except Exception as e:
            print(f"    Error: {e}")

    print("\nDone! Run the following to copy to assets:")
    print("  python3 scripts/add_borders.py --raw scripts/raw_downloads/improved_animals")


if __name__ == "__main__":
    main()
