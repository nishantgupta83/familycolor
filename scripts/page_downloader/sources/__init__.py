# Image source modules
try:
    from .pixabay import PixabaySource
except ImportError:
    PixabaySource = None

from .free_sources import FreeSourceDownloader, generate_simple_coloring_pages
