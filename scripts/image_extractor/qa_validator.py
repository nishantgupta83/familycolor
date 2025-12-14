"""
QA Validator for coloring page content.

Enforces age-group appropriate complexity limits:
- Kids (4-8): Max 150 regions, min 5000px per region
- Family (8-12): Max 300 regions, min 2000px per region
- Adult (12+): Max 1000 regions, min 500px per region
"""

from dataclasses import dataclass
from enum import Enum
from typing import List, Optional, Tuple

from .config import Config, AgeGroup
from .processors.region_extractor import RegionMetadata


class QAResult(Enum):
    """Result of QA validation."""
    PASS = "pass"
    WARN = "warn"
    FAIL = "fail"


@dataclass
class QAIssue:
    """A single QA issue found during validation."""
    severity: QAResult
    code: str
    message: str
    details: Optional[str] = None


@dataclass
class QAReport:
    """Complete QA validation report."""
    result: QAResult
    issues: List[QAIssue]
    region_count: int
    tiny_region_count: int
    tiny_region_percentage: float
    age_group: AgeGroup
    recommended_age_group: Optional[AgeGroup] = None

    @property
    def passed(self) -> bool:
        return self.result == QAResult.PASS

    def summary(self) -> str:
        """Human-readable summary of the QA report."""
        lines = [
            f"QA Result: {self.result.value.upper()}",
            f"Age Group: {self.age_group.value}",
            f"Region Count: {self.region_count}",
            f"Tiny Regions: {self.tiny_region_count} ({self.tiny_region_percentage:.1%})",
        ]

        if self.recommended_age_group and self.recommended_age_group != self.age_group:
            lines.append(f"Recommended Age Group: {self.recommended_age_group.value}")

        if self.issues:
            lines.append("\nIssues:")
            for issue in self.issues:
                lines.append(f"  [{issue.severity.value}] {issue.code}: {issue.message}")
                if issue.details:
                    lines.append(f"         {issue.details}")

        return "\n".join(lines)


class QAValidator:
    """
    Validate coloring pages meet age-group requirements.

    QA Rules:
    1. Region count must not exceed max for age group
    2. Tiny regions (below min pixel count) must not exceed 30% of total
    3. Warns if page might be better suited for different age group
    """

    def __init__(self, config: Config):
        self.config = config

    def validate(
        self,
        regions: List[RegionMetadata],
        target_age_group: AgeGroup
    ) -> QAReport:
        """
        Validate regions against age group requirements.

        Args:
            regions: List of extracted regions
            target_age_group: Intended age group for this page

        Returns:
            QAReport with validation results
        """
        issues = []
        region_count = len(regions)

        # Get limits for target age group
        max_regions = self.config.get_max_regions(target_age_group)
        min_pixels = self.config.get_min_region_pixels(target_age_group)

        # Count tiny regions
        tiny_regions = [r for r in regions if r.pixel_count < min_pixels]
        tiny_count = len(tiny_regions)
        tiny_percentage = tiny_count / region_count if region_count > 0 else 0

        # Check 1: Region count limit
        if region_count > max_regions:
            issues.append(QAIssue(
                severity=QAResult.FAIL,
                code="REGION_COUNT_EXCEEDED",
                message=f"Too many regions for {target_age_group.value} age group",
                details=f"Found {region_count}, max allowed is {max_regions}"
            ))

        # Check 2: Tiny region percentage
        if tiny_percentage > self.config.tiny_region_threshold:
            issues.append(QAIssue(
                severity=QAResult.FAIL,
                code="TOO_MANY_TINY_REGIONS",
                message=f"Too many tiny regions for {target_age_group.value} age group",
                details=f"{tiny_count} regions ({tiny_percentage:.1%}) below {min_pixels}px minimum"
            ))

        # Determine recommended age group
        recommended = self._recommend_age_group(region_count, tiny_percentage, regions)

        # Add warning if recommended differs
        if recommended != target_age_group:
            issues.append(QAIssue(
                severity=QAResult.WARN,
                code="AGE_GROUP_MISMATCH",
                message=f"Page may be better suited for {recommended.value} age group",
                details=f"Based on region count ({region_count}) and complexity"
            ))

        # Determine overall result
        has_fail = any(i.severity == QAResult.FAIL for i in issues)
        has_warn = any(i.severity == QAResult.WARN for i in issues)

        if has_fail:
            result = QAResult.FAIL
        elif has_warn:
            result = QAResult.WARN
        else:
            result = QAResult.PASS

        return QAReport(
            result=result,
            issues=issues,
            region_count=region_count,
            tiny_region_count=tiny_count,
            tiny_region_percentage=tiny_percentage,
            age_group=target_age_group,
            recommended_age_group=recommended if recommended != target_age_group else None
        )

    def _recommend_age_group(
        self,
        region_count: int,
        tiny_percentage: float,
        regions: List[RegionMetadata]
    ) -> AgeGroup:
        """
        Recommend the most appropriate age group based on complexity.

        Uses region count as primary metric.
        """
        # Calculate average region size
        if regions:
            avg_size = sum(r.pixel_count for r in regions) / len(regions)
        else:
            avg_size = 0

        # Kids: Low region count, large regions
        if region_count <= 80 and avg_size >= 10000:
            return AgeGroup.KIDS

        # Family: Moderate complexity
        if region_count <= 200 and avg_size >= 3000:
            return AgeGroup.FAMILY

        # Kids (still acceptable): Up to limit
        if region_count <= self.config.get_max_regions(AgeGroup.KIDS):
            if tiny_percentage <= 0.2:
                return AgeGroup.KIDS

        # Family (moderate): Up to limit
        if region_count <= self.config.get_max_regions(AgeGroup.FAMILY):
            if tiny_percentage <= 0.25:
                return AgeGroup.FAMILY

        # Adult: High complexity
        return AgeGroup.ADULT

    def auto_classify(self, regions: List[RegionMetadata]) -> Tuple[AgeGroup, QAReport]:
        """
        Automatically classify page and validate against recommended age group.

        Returns:
            Tuple of (recommended_age_group, qa_report)
        """
        region_count = len(regions)

        # First pass: determine recommendation
        if regions:
            avg_size = sum(r.pixel_count for r in regions) / len(regions)
            tiny_count = len([r for r in regions
                             if r.pixel_count < self.config.get_min_region_pixels(AgeGroup.FAMILY)])
            tiny_pct = tiny_count / region_count
        else:
            avg_size = 0
            tiny_pct = 0

        recommended = self._recommend_age_group(region_count, tiny_pct, regions)

        # Validate against recommended
        report = self.validate(regions, recommended)

        return recommended, report
