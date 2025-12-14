#!/usr/bin/env python3
"""
Entry point for running image_extractor as a module.

Usage:
    python -m image_extractor process input.png -o output/
    python -m image_extractor batch input_dir/ -o output/
    python -m image_extractor manifest output/ -o manifest.json
"""

from .cli import main

if __name__ == "__main__":
    main()
