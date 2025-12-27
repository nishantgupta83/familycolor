#!/bin/bash

# Maestro Test Runner for FamilyColorFun
# ======================================
# Runs all Maestro tests and generates reports

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_ID="com.familycolorfun.app"
TESTS_DIR="$(dirname "$0")/flows"
SCREENSHOTS_DIR="$(dirname "$0")/screenshots"
REPORTS_DIR="$(dirname "$0")/reports"

# Create directories
mkdir -p "$SCREENSHOTS_DIR"
mkdir -p "$REPORTS_DIR"

# Print banner
echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║     FamilyColorFun Maestro Test Suite                ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check if maestro is installed
if ! command -v maestro &> /dev/null; then
    echo -e "${RED}Error: Maestro is not installed${NC}"
    echo "Install with: curl -Ls 'https://get.maestro.mobile.dev' | bash"
    exit 1
fi

# Print maestro version
echo -e "${YELLOW}Maestro Version:${NC}"
maestro --version
echo ""

# Parse arguments
RUN_SMOKE=false
RUN_ALL=true
SINGLE_TEST=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --smoke)
            RUN_SMOKE=true
            RUN_ALL=false
            shift
            ;;
        --test)
            SINGLE_TEST="$2"
            RUN_ALL=false
            shift 2
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --smoke     Run only smoke tests"
            echo "  --test FILE Run a specific test file"
            echo "  --help      Show this help message"
            exit 0
            ;;
        *)
            shift
            ;;
    esac
done

# Function to run a test
run_test() {
    local test_file=$1
    local test_name=$(basename "$test_file" .yaml)

    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Running: $test_name${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    if maestro test "$test_file" --format junit --output "$REPORTS_DIR/${test_name}.xml" 2>&1; then
        echo -e "${GREEN}✓ $test_name PASSED${NC}"
        return 0
    else
        echo -e "${RED}✗ $test_name FAILED${NC}"
        return 1
    fi
}

# Track results
PASSED=0
FAILED=0
FAILED_TESTS=()

# Run tests
if [ -n "$SINGLE_TEST" ]; then
    # Run single test
    if run_test "$TESTS_DIR/$SINGLE_TEST"; then
        PASSED=$((PASSED + 1))
    else
        FAILED=$((FAILED + 1))
        FAILED_TESTS+=("$SINGLE_TEST")
    fi
elif [ "$RUN_SMOKE" = true ]; then
    # Run smoke tests only (app launch and home)
    SMOKE_TESTS=("01_app_launch.yaml" "02_home_screen.yaml")
    for test in "${SMOKE_TESTS[@]}"; do
        if run_test "$TESTS_DIR/$test"; then
            PASSED=$((PASSED + 1))
        else
            FAILED=$((FAILED + 1))
            FAILED_TESTS+=("$test")
        fi
    done
else
    # Run all tests
    for test_file in "$TESTS_DIR"/*.yaml; do
        if run_test "$test_file"; then
            PASSED=$((PASSED + 1))
        else
            FAILED=$((FAILED + 1))
            FAILED_TESTS+=("$(basename "$test_file")")
        fi
    done
fi

# Print summary
echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════════════╗"
echo -e "║                    TEST SUMMARY                       ║"
echo -e "╚══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo -e "Total:  $((PASSED + FAILED))"
echo ""

if [ ${#FAILED_TESTS[@]} -gt 0 ]; then
    echo -e "${RED}Failed Tests:${NC}"
    for test in "${FAILED_TESTS[@]}"; do
        echo -e "  - $test"
    done
    echo ""
fi

echo -e "${YELLOW}Screenshots saved to: $SCREENSHOTS_DIR${NC}"
echo -e "${YELLOW}Reports saved to: $REPORTS_DIR${NC}"
echo ""

# Exit with appropriate code
if [ $FAILED -gt 0 ]; then
    exit 1
else
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
fi
