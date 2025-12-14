"""
Advanced QA Validator tests with additional edge cases.
"""
import sys
sys.path.insert(0, '.')
from image_extractor.config import Config, AgeGroup
from image_extractor.qa_validator import QAValidator, QAResult
from image_extractor.processors.region_extractor import RegionMetadata

config = Config()
validator = QAValidator(config)

print("="*80)
print("ADVANCED QA VALIDATOR EDGE CASE TESTS")
print("="*80)
print()

# Test 8: Boundary test - exactly at limit (Kids: 150 regions)
print("Test 8: Kids Boundary - Exactly 150 regions")
print("-" * 40)
regions_kids_boundary = [
    RegionMetadata(i, (100, 100), (0, 0, 50, 50), 10000) for i in range(1, 151)
]
report = validator.validate(regions_kids_boundary, AgeGroup.KIDS)
print(f"Result: {report.result.value}")
print(f"Region count: {report.region_count}")
print(f"Expected: pass (exactly at limit)")
print(f"Match: {'✓' if report.result.value == 'pass' else '✗'}")
if report.issues:
    for issue in report.issues:
        print(f"  - [{issue.severity.value}] {issue.code}: {issue.message}")
print()

# Test 9: Boundary test - one over limit (Kids: 151 regions)
print("Test 9: Kids Boundary - 151 regions (one over)")
print("-" * 40)
regions_kids_over = [
    RegionMetadata(i, (100, 100), (0, 0, 50, 50), 10000) for i in range(1, 152)
]
report = validator.validate(regions_kids_over, AgeGroup.KIDS)
print(f"Result: {report.result.value}")
print(f"Region count: {report.region_count}")
print(f"Expected: fail (one over limit)")
print(f"Match: {'✓' if report.result.value == 'fail' else '✗'}")
if report.issues:
    for issue in report.issues:
        print(f"  - [{issue.severity.value}] {issue.code}: {issue.message}")
print()

# Test 10: Tiny region threshold - exactly 30% tiny
print("Test 10: Kids - Exactly 30% tiny regions (threshold)")
print("-" * 40)
regions_30pct_tiny = []
for i in range(1, 101):
    if i <= 30:
        # 30% tiny (below 5000px for kids)
        regions_30pct_tiny.append(RegionMetadata(i, (100, 100), (0, 0, 50, 50), 4000))
    else:
        # 70% acceptable
        regions_30pct_tiny.append(RegionMetadata(i, (100, 100), (0, 0, 50, 50), 10000))
report = validator.validate(regions_30pct_tiny, AgeGroup.KIDS)
print(f"Result: {report.result.value}")
print(f"Tiny regions: {report.tiny_region_count} ({report.tiny_region_percentage:.1%})")
print(f"Expected: pass (exactly at 30% threshold)")
print(f"Match: {'✓' if report.result.value == 'pass' else '✗'}")
if report.issues:
    for issue in report.issues:
        print(f"  - [{issue.severity.value}] {issue.code}: {issue.message}")
print()

# Test 11: Tiny region threshold - 31% tiny (over threshold)
print("Test 11: Kids - 31% tiny regions (over threshold)")
print("-" * 40)
regions_31pct_tiny = []
for i in range(1, 101):
    if i <= 31:
        # 31% tiny
        regions_31pct_tiny.append(RegionMetadata(i, (100, 100), (0, 0, 50, 50), 4000))
    else:
        # 69% acceptable
        regions_31pct_tiny.append(RegionMetadata(i, (100, 100), (0, 0, 50, 50), 10000))
report = validator.validate(regions_31pct_tiny, AgeGroup.KIDS)
print(f"Result: {report.result.value}")
print(f"Tiny regions: {report.tiny_region_count} ({report.tiny_region_percentage:.1%})")
print(f"Expected: fail (over 30% threshold)")
print(f"Match: {'✓' if report.result.value == 'fail' else '✗'}")
if report.issues:
    for issue in report.issues:
        print(f"  - [{issue.severity.value}] {issue.code}: {issue.message}")
print()

# Test 12: Mixed complexity - should recommend family
print("Test 12: Auto-classify - Mixed complexity (120 regions, 3000px avg)")
print("-" * 40)
regions_mixed = [
    RegionMetadata(i, (100, 100), (0, 0, 50, 50), 3000) for i in range(1, 121)
]
recommended, report = validator.auto_classify(regions_mixed)
print(f"Recommended: {recommended.value}")
print(f"Region count: {report.region_count}")
print(f"Expected: family")
print(f"Match: {'✓' if recommended.value == 'family' else '✗'}")
print()

# Test 13: High complexity - should recommend adult
print("Test 13: Auto-classify - High complexity (500 regions, 1500px avg)")
print("-" * 40)
regions_complex = [
    RegionMetadata(i, (100, 100), (0, 0, 50, 50), 1500) for i in range(1, 501)
]
recommended, report = validator.auto_classify(regions_complex)
print(f"Recommended: {recommended.value}")
print(f"Region count: {report.region_count}")
print(f"Expected: adult")
print(f"Match: {'✓' if recommended.value == 'adult' else '✗'}")
print()

# Test 14: Single region
print("Test 14: Single region")
print("-" * 40)
regions_single = [RegionMetadata(1, (100, 100), (0, 0, 50, 50), 10000)]
report = validator.validate(regions_single, AgeGroup.KIDS)
print(f"Result: {report.result.value}")
print(f"Region count: {report.region_count}")
print(f"Expected: pass")
print(f"Match: {'✓' if report.result.value == 'pass' else '✗'}")
print()

# Test 15: Family boundary test
print("Test 15: Family Boundary - Exactly 300 regions")
print("-" * 40)
regions_family_boundary = [
    RegionMetadata(i, (100, 100), (0, 0, 50, 50), 3000) for i in range(1, 301)
]
report = validator.validate(regions_family_boundary, AgeGroup.FAMILY)
print(f"Result: {report.result.value}")
print(f"Region count: {report.region_count}")
print(f"Expected: pass")
print(f"Match: {'✓' if report.result.value == 'pass' else '✗'}")
if report.issues:
    for issue in report.issues:
        print(f"  - [{issue.severity.value}] {issue.code}: {issue.message}")
print()

# Test 16: Adult boundary test
print("Test 16: Adult Boundary - Exactly 1000 regions")
print("-" * 40)
regions_adult_boundary = [
    RegionMetadata(i, (100, 100), (0, 0, 50, 50), 1000) for i in range(1, 1001)
]
report = validator.validate(regions_adult_boundary, AgeGroup.ADULT)
print(f"Result: {report.result.value}")
print(f"Region count: {report.region_count}")
print(f"Expected: pass")
print(f"Match: {'✓' if report.result.value == 'pass' else '✗'}")
if report.issues:
    for issue in report.issues:
        print(f"  - [{issue.severity.value}] {issue.code}: {issue.message}")
print()

print("="*80)
print("All advanced tests completed!")
print("="*80)
