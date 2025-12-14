"""
Test QA Validator with various edge cases.
"""
import sys
sys.path.insert(0, '.')
from image_extractor.config import Config, AgeGroup
from image_extractor.qa_validator import QAValidator, QAResult
from image_extractor.processors.region_extractor import RegionMetadata

config = Config()
validator = QAValidator(config)

print("="*80)
print("QA VALIDATOR EDGE CASE TESTS")
print("="*80)
print()

# Test 1: Kids age group with acceptable regions
print("Test 1: Kids OK (50 regions, large)")
print("-" * 40)
regions_kids_ok = [
    RegionMetadata(i, (100, 100), (0, 0, 50, 50), 10000) for i in range(1, 51)
]
report = validator.validate(regions_kids_ok, AgeGroup.KIDS)
print(f"Result: {report.result.value}")
print(f"Region count: {report.region_count}")
print(f"Tiny regions: {report.tiny_region_count} ({report.tiny_region_percentage:.1%})")
print(f"Expected: pass")
print(f"Match: {'✓' if report.result.value == 'pass' else '✗'}")
print()

# Test 2: Kids age group with too many regions
print("Test 2: Kids Too Many (199 regions)")
print("-" * 40)
regions_kids_fail = [
    RegionMetadata(i, (100, 100), (0, 0, 50, 50), 10000) for i in range(1, 200)
]
report = validator.validate(regions_kids_fail, AgeGroup.KIDS)
print(f"Result: {report.result.value}")
print(f"Region count: {report.region_count}")
print(f"Expected: fail")
print(f"Match: {'✓' if report.result.value == 'fail' else '✗'}")
if report.issues:
    print("Issues found:")
    for issue in report.issues:
        print(f"  - [{issue.severity.value}] {issue.code}: {issue.message}")
print()

# Test 3: Kids with too many tiny regions
print("Test 3: Kids Tiny Regions (50 regions @ 1000px)")
print("-" * 40)
regions_kids_tiny = [
    RegionMetadata(i, (100, 100), (0, 0, 50, 50), 1000) for i in range(1, 51)
]
report = validator.validate(regions_kids_tiny, AgeGroup.KIDS)
print(f"Result: {report.result.value}")
print(f"Region count: {report.region_count}")
print(f"Tiny regions: {report.tiny_region_count} ({report.tiny_region_percentage:.1%})")
print(f"Expected: fail")
print(f"Match: {'✓' if report.result.value == 'fail' else '✗'}")
if report.issues:
    print("Issues found:")
    for issue in report.issues:
        print(f"  - [{issue.severity.value}] {issue.code}: {issue.message}")
print()

# Test 4: Family age group
print("Test 4: Family (249 regions)")
print("-" * 40)
regions_family = [
    RegionMetadata(i, (100, 100), (0, 0, 50, 50), 5000) for i in range(1, 250)
]
report = validator.validate(regions_family, AgeGroup.FAMILY)
print(f"Result: {report.result.value}")
print(f"Region count: {report.region_count}")
print(f"Tiny regions: {report.tiny_region_count} ({report.tiny_region_percentage:.1%})")
print(f"Expected: pass")
print(f"Match: {'✓' if report.result.value == 'pass' else '✗'}")
if report.issues:
    print("Issues found:")
    for issue in report.issues:
        print(f"  - [{issue.severity.value}] {issue.code}: {issue.message}")
print()

# Test 5: Adult age group
print("Test 5: Adult (799 regions)")
print("-" * 40)
regions_adult = [
    RegionMetadata(i, (100, 100), (0, 0, 50, 50), 1000) for i in range(1, 800)
]
report = validator.validate(regions_adult, AgeGroup.ADULT)
print(f"Result: {report.result.value}")
print(f"Region count: {report.region_count}")
print(f"Tiny regions: {report.tiny_region_count} ({report.tiny_region_percentage:.1%})")
print(f"Expected: pass")
print(f"Match: {'✓' if report.result.value == 'pass' else '✗'}")
if report.issues:
    print("Issues found:")
    for issue in report.issues:
        print(f"  - [{issue.severity.value}] {issue.code}: {issue.message}")
print()

# Test 6: Auto-classification
print("Test 6: Auto-classify (50 large regions)")
print("-" * 40)
recommended, report = validator.auto_classify(regions_kids_ok)
print(f"Recommended age group: {recommended.value}")
print(f"Validation result: {report.result.value}")
print(f"Expected: kids")
print(f"Match: {'✓' if recommended.value == 'kids' else '✗'}")
print()

# Test 7: Empty regions
print("Test 7: Empty regions")
print("-" * 40)
report = validator.validate([], AgeGroup.KIDS)
print(f"Result: {report.result.value}")
print(f"Region count: {report.region_count}")
print(f"Expected: pass")
print(f"Match: {'✓' if report.result.value == 'pass' else '✗'}")
print()

# Summary
print("="*80)
print("TEST SUMMARY")
print("="*80)
results = [
    ("Test 1: Kids OK", "pass", report.result.value == "pass"),
    ("Test 2: Kids Too Many", "fail", True),  # Need to track
    ("Test 3: Kids Tiny Regions", "fail", True),  # Need to track
    ("Test 4: Family", "pass", True),  # Need to track
    ("Test 5: Adult", "pass", True),  # Need to track
    ("Test 6: Auto-classify", "kids", True),  # Need to track
    ("Test 7: Empty regions", "pass", True),  # Need to track
]
print("All tests completed. Review individual test results above.")
