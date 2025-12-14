"""
FamilyColorFun Image Extractor Pipeline

Processes scanned coloring book pages into:
- Clean line art (2048x2048)
- RGB-encoded label maps
- Region metadata JSON
- Thumbnails (256x256)
"""

from .pipeline import Pipeline
from .config import Config, AgeGroup
from .qa_validator import QAValidator, QAResult

__version__ = "1.0.0"
__all__ = ["Pipeline", "Config", "AgeGroup", "QAValidator", "QAResult"]
