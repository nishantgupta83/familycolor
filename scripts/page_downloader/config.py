"""
Configuration for coloring page downloader.
"""
import os
from pathlib import Path
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Base paths
BASE_DIR = Path(__file__).parent.parent
RAW_DOWNLOADS_DIR = BASE_DIR / "raw_downloads"
PROCESSED_DIR = BASE_DIR / "processed"

# API Keys (set in .env file)
PIXABAY_API_KEY = os.getenv("PIXABAY_API_KEY", "")

# Download settings
MIN_IMAGE_WIDTH = 1024
MIN_IMAGE_HEIGHT = 1024
TARGET_RESOLUTION = 2048

# Categories and search terms
SEARCH_CATEGORIES = {
    "mandalas": [
        "mandala coloring",
        "zentangle pattern",
        "geometric mandala",
        "circular pattern",
        "symmetrical design"
    ],
    "animals": [
        "animal coloring page",
        "wildlife line art",
        "bird illustration outline",
        "cat line drawing",
        "elephant coloring"
    ],
    "nature": [
        "flower coloring page",
        "nature line art",
        "tree outline drawing",
        "butterfly coloring",
        "garden illustration"
    ],
    "fantasy": [
        "dragon line art",
        "fairy coloring page",
        "unicorn outline",
        "mermaid illustration",
        "fantasy creature drawing"
    ]
}

# Target counts per category
CATEGORY_TARGETS = {
    "mandalas": 15,
    "animals": 12,
    "nature": 8,
    "fantasy": 10
}

# Pixabay API settings
PIXABAY_BASE_URL = "https://pixabay.com/api/"
PIXABAY_PARAMS = {
    "image_type": "illustration",
    "orientation": "all",
    "min_width": MIN_IMAGE_WIDTH,
    "min_height": MIN_IMAGE_HEIGHT,
    "safesearch": "true",
    "per_page": 50  # Max allowed
}

# Image validation thresholds
MAX_COLOR_VARIANCE = 50  # For detecting line art (low color variance)
MIN_WHITE_PERCENTAGE = 0.4  # At least 40% white pixels
MAX_BLACK_PERCENTAGE = 0.3  # At most 30% black pixels
