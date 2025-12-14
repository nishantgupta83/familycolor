"""
Comprehensive QA Validator test suite with all edge cases.
Generates detailed results for validation.
"""
import sys
sys.path.insert(0, '.')
from image_extractor.config import Config, AgeGroup
from image_extractor.qa_validator import QAValidator, QAResult
from image_extractor.processors.region_extractor import RegionMetadata

def run_test(test_num, description, regions, age_group, expected_result, validator, test_type="validate"):
    """Run a single test and return results."""
    print(f"Test {test_num}: {description}")
    print("-" * 60)

    if test_type == "auto_classify":
        recommended, report = validator.auto_classify(regions)
        result = recommended.value
        print(f"Recommended: {recommended.value}")
        print(f"Validation: {report.result.value}")
    else:
        report = validator.validate(regions, age_group)
        result = report.result.value
        print(f"Result: {result}")

    print(f"Region count: {report.region_count}")
    if report.region_count > 0:
        print(f"Tiny regions: {report.tiny_region_count} ({report.tiny_region_percentage:.1%})")

    if report.issues:
        print("Issues:")
        for issue in report.issues:
            print(f"  [{issue.severity.value}] {issue.code}: {issue.message}")

    # Determine if test passed
    if test_type == "auto_classify":
        passed = result == expected_result
    else:
        passed = result == expected_result

    print(f"Expected: {expected_result}")
    print(f"Status: {'✓ PASS' if passed else '✗ FAIL'}")
    print()

    return {
        'num': test_num,
        'description': description,
        'expected': expected_result,
        'actual': result,
        'passed': passed,
        'report': report
    }

def main():
    config = Config()
    validator = QAValidator(config)

    results = []

    print("="*80)
    print("COMPREHENSIVE QA VALIDATOR TEST SUITE")
    print("="*80)
    print()

    # Basic Tests (1-7)
    print("BASIC EDGE CASES")
    print("="*80)
    print()

    # Test 1
    regions = [RegionMetadata(i, (100, 100), (0, 0, 50, 50), 10000) for i in range(1, 51)]
    results.append(run_test(1, "Kids OK (50 regions, large)", regions, AgeGroup.KIDS, "pass", validator))

    # Test 2
    regions = [RegionMetadata(i, (100, 100), (0, 0, 50, 50), 10000) for i in range(1, 200)]
    results.append(run_test(2, "Kids Too Many (199 regions)", regions, AgeGroup.KIDS, "fail", validator))

    # Test 3
    regions = [RegionMetadata(i, (100, 100), (0, 0, 50, 50), 1000) for i in range(1, 51)]
    results.append(run_test(3, "Kids Tiny Regions (50 @ 1000px)", regions, AgeGroup.KIDS, "fail", validator))

    # Test 4
    regions = [RegionMetadata(i, (100, 100), (0, 0, 50, 50), 5000) for i in range(1, 250)]
    results.append(run_test(4, "Family (249 regions)", regions, AgeGroup.FAMILY, "pass", validator))

    # Test 5
    regions = [RegionMetadata(i, (100, 100), (0, 0, 50, 50), 1000) for i in range(1, 800)]
    results.append(run_test(5, "Adult (799 regions)", regions, AgeGroup.ADULT, "pass", validator))

    # Test 6
    regions = [RegionMetadata(i, (100, 100), (0, 0, 50, 50), 10000) for i in range(1, 51)]
    results.append(run_test(6, "Auto-classify (50 large regions)", regions, None, "kids", validator, "auto_classify"))

    # Test 7
    regions = []
    results.append(run_test(7, "Empty regions", regions, AgeGroup.KIDS, "pass", validator))

    # Advanced Tests (8-16)
    print("\nADVANCED EDGE CASES")
    print("="*80)
    print()

    # Test 8
    regions = [RegionMetadata(i, (100, 100), (0, 0, 50, 50), 10000) for i in range(1, 151)]
    results.append(run_test(8, "Kids Boundary (exactly 150)", regions, AgeGroup.KIDS, "pass", validator))

    # Test 9
    regions = [RegionMetadata(i, (100, 100), (0, 0, 50, 50), 10000) for i in range(1, 152)]
    results.append(run_test(9, "Kids Over Limit (151)", regions, AgeGroup.KIDS, "fail", validator))

    # Test 10
    regions = []
    for i in range(1, 101):
        if i <= 30:
            regions.append(RegionMetadata(i, (100, 100), (0, 0, 50, 50), 4000))
        else:
            regions.append(RegionMetadata(i, (100, 100), (0, 0, 50, 50), 10000))
    results.append(run_test(10, "Kids 30% Tiny (threshold)", regions, AgeGroup.KIDS, "pass", validator))

    # Test 11
    regions = []
    for i in range(1, 101):
        if i <= 31:
            regions.append(RegionMetadata(i, (100, 100), (0, 0, 50, 50), 4000))
        else:
            regions.append(RegionMetadata(i, (100, 100), (0, 0, 50, 50), 10000))
    results.append(run_test(11, "Kids 31% Tiny (over threshold)", regions, AgeGroup.KIDS, "fail", validator))

    # Test 12
    regions = [RegionMetadata(i, (100, 100), (0, 0, 50, 50), 3000) for i in range(1, 121)]
    results.append(run_test(12, "Auto-classify Mixed (120 @ 3000px)", regions, None, "family", validator, "auto_classify"))

    # Test 13
    regions = [RegionMetadata(i, (100, 100), (0, 0, 50, 50), 1500) for i in range(1, 501)]
    results.append(run_test(13, "Auto-classify Complex (500 @ 1500px)", regions, None, "adult", validator, "auto_classify"))

    # Test 14
    regions = [RegionMetadata(1, (100, 100), (0, 0, 50, 50), 10000)]
    results.append(run_test(14, "Single region", regions, AgeGroup.KIDS, "pass", validator))

    # Test 15
    regions = [RegionMetadata(i, (100, 100), (0, 0, 50, 50), 3000) for i in range(1, 301)]
    results.append(run_test(15, "Family Boundary (exactly 300)", regions, AgeGroup.FAMILY, "pass", validator))

    # Test 16
    regions = [RegionMetadata(i, (100, 100), (0, 0, 50, 50), 1000) for i in range(1, 1001)]
    results.append(run_test(16, "Adult Boundary (exactly 1000)", regions, AgeGroup.ADULT, "pass", validator))

    # Summary
    print("="*80)
    print("TEST SUMMARY")
    print("="*80)
    print()

    total_tests = len(results)
    passed_tests = sum(1 for r in results if r['passed'])
    failed_tests = total_tests - passed_tests

    print(f"Total Tests: {total_tests}")
    print(f"Passed: {passed_tests} ({passed_tests/total_tests*100:.1f}%)")
    print(f"Failed: {failed_tests} ({failed_tests/total_tests*100:.1f}%)")
    print()

    if failed_tests > 0:
        print("Failed Tests:")
        for r in results:
            if not r['passed']:
                print(f"  Test {r['num']}: {r['description']}")
                print(f"    Expected: {r['expected']}, Got: {r['actual']}")
        print()

    print("Detailed Results:")
    print()
    print(f"{'Test':<6} {'Description':<40} {'Expected':<10} {'Actual':<10} {'Status':<10}")
    print("-" * 80)
    for r in results:
        status = "✓ PASS" if r['passed'] else "✗ FAIL"
        desc = r['description'][:38]
        print(f"{r['num']:<6} {desc:<40} {r['expected']:<10} {r['actual']:<10} {status:<10}")

    print()
    print("="*80)
    print(f"OVERALL: {passed_tests}/{total_tests} tests passed")
    print("="*80)

if __name__ == "__main__":
    main()
