"""
Main orchestrator for the image extraction pipeline.

Processes scanned coloring pages into CDN-ready assets:
- Clean line art (2048x2048 PNG)
- RGB-encoded label map
- Region metadata JSON
- Thumbnail (256x256 PNG)
"""

import json
import shutil
from dataclasses import dataclass
from pathlib import Path
from typing import Optional, Dict, Any, List

import cv2

from .config import Config, AgeGroup
from .processors import LineExtractor, RegionExtractor, ThumbnailGenerator
from .qa_validator import QAValidator, QAReport, QAResult


@dataclass
class ProcessingResult:
    """Result of processing a single page."""
    page_id: str
    success: bool
    qa_report: Optional[QAReport] = None
    metadata: Optional[Dict[str, Any]] = None
    error: Optional[str] = None
    output_dir: Optional[Path] = None


class Pipeline:
    """
    Main image extraction pipeline.

    Usage:
        config = Config()
        pipeline = Pipeline(config)
        result = pipeline.process_page(
            input_path=Path("scan.png"),
            page_id="retro_boombox_01",
            output_dir=Path("processed"),
            age_group=AgeGroup.KIDS
        )
    """

    def __init__(self, config: Optional[Config] = None):
        self.config = config or Config()
        self.line_extractor = LineExtractor(self.config)
        self.region_extractor = RegionExtractor(self.config)
        self.thumbnail_gen = ThumbnailGenerator(self.config)
        self.qa_validator = QAValidator(self.config)

    def process_page(
        self,
        input_path: Path,
        page_id: str,
        output_dir: Path,
        age_group: Optional[AgeGroup] = None,
        skip_qa_fail: bool = False,
    ) -> ProcessingResult:
        """
        Process a single coloring page.

        Args:
            input_path: Path to input image (scanned/photographed)
            page_id: Unique identifier for this page
            output_dir: Base directory for output
            age_group: Target age group (auto-detected if None)
            skip_qa_fail: If True, save output even if QA fails

        Returns:
            ProcessingResult with status and outputs
        """
        try:
            # Create output directory
            page_output_dir = output_dir / page_id
            page_output_dir.mkdir(parents=True, exist_ok=True)

            # Step 1: Extract clean lines
            print(f"[{page_id}] Extracting lines...")
            line_art, fillable = self.line_extractor.extract(input_path)

            # Step 2: Extract regions
            print(f"[{page_id}] Extracting regions...")
            label_map, regions = self.region_extractor.extract(fillable)
            print(f"[{page_id}] Found {len(regions)} fillable regions")

            # Step 3: QA validation
            if age_group is None:
                # Auto-classify
                age_group, qa_report = self.qa_validator.auto_classify(regions)
                print(f"[{page_id}] Auto-classified as {age_group.value}")
            else:
                qa_report = self.qa_validator.validate(regions, age_group)

            print(f"[{page_id}] QA Result: {qa_report.result.value}")

            # Check if we should abort
            if qa_report.result == QAResult.FAIL and not skip_qa_fail:
                print(f"[{page_id}] QA FAILED - skipping output")
                print(qa_report.summary())
                return ProcessingResult(
                    page_id=page_id,
                    success=False,
                    qa_report=qa_report,
                    error="QA validation failed"
                )

            # Step 4: Save outputs
            print(f"[{page_id}] Saving outputs...")

            # Line art
            cv2.imwrite(str(page_output_dir / "image.png"), line_art)

            # RGB label map
            self.region_extractor.save_rgb_label_map(
                label_map,
                page_output_dir / "labels.png"
            )

            # Thumbnail
            self.thumbnail_gen.generate(
                line_art,
                page_output_dir / "thumb.png"
            )

            # Metadata
            metadata = self.region_extractor.build_metadata(
                page_id=page_id,
                image_size=(self.config.target_resolution, self.config.target_resolution),
                regions=regions,
                label_map_name=f"{page_id}_labels"
            )

            # Add QA info to metadata
            metadata["qaResult"] = qa_report.result.value
            metadata["ageGroup"] = age_group.value

            with open(page_output_dir / "metadata.json", "w") as f:
                json.dump(metadata, f, indent=2)

            # Debug outputs (if enabled)
            if self.config.debug_output:
                debug_dir = page_output_dir / "_debug"
                debug_dir.mkdir(exist_ok=True)

                self.line_extractor.save_debug_images(
                    debug_dir, page_id, line_art, fillable
                )
                self.region_extractor.save_debug_preview(
                    label_map,
                    debug_dir / f"{page_id}_regions_preview.png"
                )
                self.thumbnail_gen.generate_preview_with_regions(
                    line_art, label_map,
                    debug_dir / f"{page_id}_thumb_regions.png"
                )

            print(f"[{page_id}] Complete!")

            return ProcessingResult(
                page_id=page_id,
                success=True,
                qa_report=qa_report,
                metadata=metadata,
                output_dir=page_output_dir
            )

        except Exception as e:
            print(f"[{page_id}] ERROR: {e}")
            import traceback
            traceback.print_exc()
            return ProcessingResult(
                page_id=page_id,
                success=False,
                error=str(e)
            )

    def process_batch(
        self,
        input_dir: Path,
        output_dir: Path,
        age_group: Optional[AgeGroup] = None,
        skip_qa_fail: bool = False,
        file_extensions: tuple = (".png", ".jpg", ".jpeg"),
    ) -> List[ProcessingResult]:
        """
        Process all images in a directory.

        Args:
            input_dir: Directory containing input images
            output_dir: Base directory for outputs
            age_group: Target age group (auto-detect if None)
            skip_qa_fail: Save outputs even if QA fails
            file_extensions: File extensions to process

        Returns:
            List of ProcessingResult for each page
        """
        results = []
        input_files = []

        for ext in file_extensions:
            input_files.extend(input_dir.glob(f"*{ext}"))
            input_files.extend(input_dir.glob(f"*{ext.upper()}"))

        # Sort for consistent ordering
        input_files = sorted(set(input_files))

        print(f"Found {len(input_files)} images to process")

        for i, input_path in enumerate(input_files, 1):
            # Skip already-processed files
            if "_labels" in input_path.stem or "_debug" in input_path.stem:
                continue
            if input_path.stem.endswith("_thumb"):
                continue

            # Generate page_id from filename
            page_id = self._generate_page_id(input_path)

            print(f"\n[{i}/{len(input_files)}] Processing: {input_path.name}")

            result = self.process_page(
                input_path=input_path,
                page_id=page_id,
                output_dir=output_dir,
                age_group=age_group,
                skip_qa_fail=skip_qa_fail,
            )
            results.append(result)

        # Print summary
        self._print_summary(results)

        return results

    def _generate_page_id(self, input_path: Path) -> str:
        """Generate page ID from input filename."""
        stem = input_path.stem.lower()

        # Clean up common patterns
        stem = stem.replace(" ", "_")
        stem = stem.replace("-", "_")

        # Remove duplicate underscores
        while "__" in stem:
            stem = stem.replace("__", "_")

        return stem

    def _print_summary(self, results: List[ProcessingResult]):
        """Print processing summary."""
        total = len(results)
        success = sum(1 for r in results if r.success)
        qa_fail = sum(1 for r in results if r.qa_report and r.qa_report.result == QAResult.FAIL)
        qa_warn = sum(1 for r in results if r.qa_report and r.qa_report.result == QAResult.WARN)
        errors = sum(1 for r in results if r.error and not r.qa_report)

        print("\n" + "=" * 50)
        print("PROCESSING SUMMARY")
        print("=" * 50)
        print(f"Total processed: {total}")
        print(f"Success: {success}")
        print(f"QA Pass: {success - qa_warn}")
        print(f"QA Warn: {qa_warn}")
        print(f"QA Fail: {qa_fail}")
        print(f"Errors: {errors}")
        print("=" * 50)

        # List failed pages
        if qa_fail > 0:
            print("\nQA Failed Pages:")
            for r in results:
                if r.qa_report and r.qa_report.result == QAResult.FAIL:
                    print(f"  - {r.page_id}: {r.qa_report.issues[0].message}")

        if errors > 0:
            print("\nError Pages:")
            for r in results:
                if r.error and not r.qa_report:
                    print(f"  - {r.page_id}: {r.error}")
