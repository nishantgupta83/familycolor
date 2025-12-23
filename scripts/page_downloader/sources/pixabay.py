"""
Pixabay API integration for downloading free coloring pages.
"""
import time
import requests
from pathlib import Path
from typing import List, Dict, Optional
from urllib.parse import urlencode

from ..config import (
    PIXABAY_API_KEY,
    PIXABAY_BASE_URL,
    PIXABAY_PARAMS,
    RAW_DOWNLOADS_DIR
)
from ..utils import (
    validate_image_size,
    is_line_art,
    is_duplicate,
    cleanup_filename,
    get_image_info
)


class PixabaySource:
    """Download coloring pages from Pixabay."""

    def __init__(self, api_key: Optional[str] = None):
        self.api_key = api_key or PIXABAY_API_KEY
        if not self.api_key:
            raise ValueError(
                "Pixabay API key required. Set PIXABAY_API_KEY in .env file.\n"
                "Get free key at: https://pixabay.com/api/docs/"
            )
        self.session = requests.Session()
        self.downloaded_hashes = set()
        self.rate_limit_delay = 0.5  # Seconds between requests

    def search(self, query: str, page: int = 1) -> Dict:
        """Search Pixabay for images."""
        params = {
            "key": self.api_key,
            "q": query,
            "page": page,
            **PIXABAY_PARAMS
        }

        url = f"{PIXABAY_BASE_URL}?{urlencode(params)}"

        try:
            response = self.session.get(url, timeout=30)
            response.raise_for_status()
            return response.json()
        except requests.RequestException as e:
            print(f"Search error for '{query}': {e}")
            return {"hits": [], "totalHits": 0}

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
            print(f"Download error: {e}")
            return False

    def search_and_download(
        self,
        category: str,
        search_terms: List[str],
        target_count: int,
        output_dir: Optional[Path] = None
    ) -> List[Dict]:
        """
        Search and download images for a category.
        Returns list of downloaded image info.
        """
        if output_dir is None:
            output_dir = RAW_DOWNLOADS_DIR / category

        output_dir.mkdir(parents=True, exist_ok=True)

        downloaded = []
        seen_ids = set()

        print(f"\n{'='*50}")
        print(f"Downloading {category.upper()} coloring pages")
        print(f"Target: {target_count} images")
        print(f"{'='*50}")

        for term in search_terms:
            if len(downloaded) >= target_count:
                break

            print(f"\n  Searching: '{term}'")

            # Search multiple pages if needed
            for page in range(1, 4):  # Max 3 pages per term
                if len(downloaded) >= target_count:
                    break

                time.sleep(self.rate_limit_delay)  # Rate limiting

                results = self.search(term, page)
                hits = results.get("hits", [])

                if not hits:
                    break

                for hit in hits:
                    if len(downloaded) >= target_count:
                        break

                    image_id = hit.get("id")
                    if image_id in seen_ids:
                        continue
                    seen_ids.add(image_id)

                    # Get largest available URL
                    image_url = (
                        hit.get("largeImageURL") or
                        hit.get("webformatURL") or
                        hit.get("previewURL")
                    )

                    if not image_url:
                        continue

                    # Check dimensions from API response
                    width = hit.get("imageWidth", 0)
                    height = hit.get("imageHeight", 0)

                    if width < 1024 or height < 1024:
                        continue

                    # Generate filename
                    tags = hit.get("tags", "image").split(",")[0].strip()
                    filename = cleanup_filename(f"{category}_{tags}_{image_id}")
                    save_path = output_dir / f"{filename}.jpg"

                    if save_path.exists():
                        continue

                    # Download
                    print(f"    Downloading: {filename[:40]}...")

                    if not self.download_image(image_url, save_path):
                        continue

                    # Validate downloaded image
                    if not validate_image_size(save_path):
                        print(f"      ✗ Too small, removing")
                        save_path.unlink()
                        continue

                    # Check for duplicates
                    if is_duplicate(save_path, self.downloaded_hashes):
                        print(f"      ✗ Duplicate, removing")
                        save_path.unlink()
                        continue

                    # Validate as line art
                    is_valid, reason = is_line_art(save_path)
                    if not is_valid:
                        print(f"      ✗ Not line art: {reason}")
                        save_path.unlink()
                        continue

                    # Success!
                    info = get_image_info(save_path)
                    info["source"] = "pixabay"
                    info["source_id"] = image_id
                    info["source_url"] = hit.get("pageURL", "")
                    info["tags"] = hit.get("tags", "")
                    info["category"] = category

                    downloaded.append(info)
                    print(f"      ✓ Saved ({len(downloaded)}/{target_count})")

        print(f"\n  Downloaded {len(downloaded)} images for {category}")
        return downloaded

    def download_all_categories(self, categories: Dict[str, List[str]], targets: Dict[str, int]) -> Dict:
        """Download images for all categories."""
        all_downloads = {}

        for category, search_terms in categories.items():
            target = targets.get(category, 10)
            downloads = self.search_and_download(category, search_terms, target)
            all_downloads[category] = downloads

        # Summary
        total = sum(len(d) for d in all_downloads.values())
        print(f"\n{'='*50}")
        print(f"DOWNLOAD COMPLETE: {total} total images")
        for cat, downloads in all_downloads.items():
            print(f"  {cat}: {len(downloads)} images")
        print(f"{'='*50}\n")

        return all_downloads
