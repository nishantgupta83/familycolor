#!/bin/bash

# ===========================================
# PERSONA TEST ORCHESTRATOR
# ===========================================
# Runs 3 different user personas through the app
# and validates their workflows independently
#
# Personas:
#   1. Emma (5 yrs) - Simple coloring, bright colors
#   2. Jake (8 yrs) - Strategic unlocking, multi-category
#   3. Sophia (13 yrs) - Artistic, metallic colors, all features
# ===========================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Ensure Maestro is in PATH
export PATH="$PATH:$HOME/.maestro/bin"

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_DIR="$SCRIPT_DIR/results"
SCREENSHOTS_DIR="$SCRIPT_DIR/../screenshots/personas"

# Create directories
mkdir -p "$RESULTS_DIR"
mkdir -p "$SCREENSHOTS_DIR"

# Timestamp for this run
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
RUN_DIR="$RESULTS_DIR/run_$TIMESTAMP"
mkdir -p "$RUN_DIR"

# Log file
LOG_FILE="$RUN_DIR/orchestrator.log"

# Function to log messages
log() {
    local level=$1
    local message=$2
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"

    case $level in
        "INFO")  echo -e "${CYAN}[$level]${NC} $message" ;;
        "SUCCESS") echo -e "${GREEN}[$level]${NC} $message" ;;
        "WARNING") echo -e "${YELLOW}[$level]${NC} $message" ;;
        "ERROR") echo -e "${RED}[$level]${NC} $message" ;;
        "PERSONA") echo -e "${PURPLE}[$level]${NC} $message" ;;
    esac
}

# Function to run a persona test
run_persona() {
    local persona_name=$1
    local persona_file=$2
    local persona_emoji=$3

    log "PERSONA" "$persona_emoji Running $persona_name..."

    local start_time=$(date +%s)
    local output_file="$RUN_DIR/${persona_name// /_}.log"

    if maestro test "$SCRIPT_DIR/$persona_file" > "$output_file" 2>&1; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        log "SUCCESS" "$persona_emoji $persona_name completed in ${duration}s"
        echo "PASSED" > "$RUN_DIR/${persona_name// /_}.status"
        return 0
    else
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        log "ERROR" "$persona_emoji $persona_name FAILED after ${duration}s"
        echo "FAILED" > "$RUN_DIR/${persona_name// /_}.status"
        return 1
    fi
}

# Function to validate results
validate_results() {
    log "INFO" "Validating test results..."

    local passed=0
    local failed=0

    for status_file in "$RUN_DIR"/*.status; do
        if [[ -f "$status_file" ]]; then
            local status=$(cat "$status_file")
            local persona=$(basename "$status_file" .status)

            if [[ "$status" == "PASSED" ]]; then
                ((passed++))
            else
                ((failed++))
            fi
        fi
    done

    echo ""
    echo "==========================================="
    echo -e "${PURPLE}       PERSONA TEST RESULTS${NC}"
    echo "==========================================="
    echo ""

    # Show individual results
    for status_file in "$RUN_DIR"/*.status; do
        if [[ -f "$status_file" ]]; then
            local status=$(cat "$status_file")
            local persona=$(basename "$status_file" .status | sed 's/_/ /g')

            if [[ "$status" == "PASSED" ]]; then
                echo -e "  ${GREEN}✓${NC} $persona"
            else
                echo -e "  ${RED}✗${NC} $persona"
            fi
        fi
    done

    echo ""
    echo "-------------------------------------------"
    echo -e "  Total: $((passed + failed)) | ${GREEN}Passed: $passed${NC} | ${RED}Failed: $failed${NC}"
    echo "-------------------------------------------"
    echo ""

    # Check screenshots
    local screenshot_count=$(find "$SCREENSHOTS_DIR" -name "p*.png" 2>/dev/null | wc -l)
    echo -e "  ${CYAN}Screenshots captured: $screenshot_count${NC}"
    echo "  Location: $SCREENSHOTS_DIR"
    echo ""

    # Summary
    if [[ $failed -eq 0 ]]; then
        echo -e "${GREEN}==========================================="
        echo "  ALL PERSONAS COMPLETED SUCCESSFULLY!"
        echo -e "===========================================${NC}"
        return 0
    else
        echo -e "${RED}==========================================="
        echo "  SOME PERSONAS FAILED - CHECK LOGS"
        echo -e "===========================================${NC}"
        return 1
    fi
}

# Main execution
main() {
    echo ""
    echo -e "${PURPLE}==========================================="
    echo "       PERSONA TEST ORCHESTRATOR"
    echo "===========================================${NC}"
    echo ""

    log "INFO" "Starting persona test run at $TIMESTAMP"
    log "INFO" "Results directory: $RUN_DIR"

    # Reset app state before running (optional)
    log "INFO" "Preparing test environment..."

    echo ""
    echo "Running 3 personas sequentially..."
    echo ""

    # Track overall status
    local overall_status=0

    # Run Persona 1: Emma (Young Child)
    echo "-------------------------------------------"
    run_persona "Persona 1 Emma" "persona_1_young_child.yaml" "👧" || overall_status=1
    echo ""

    # Small delay between personas
    sleep 2

    # Run Persona 2: Jake (Older Child)
    echo "-------------------------------------------"
    run_persona "Persona 2 Jake" "persona_2_older_child.yaml" "👦" || overall_status=1
    echo ""

    # Small delay
    sleep 2

    # Run Persona 3: Sophia (Teen/Creative)
    echo "-------------------------------------------"
    run_persona "Persona 3 Sophia" "persona_3_teen_creative.yaml" "👩‍🎨" || overall_status=1
    echo ""

    # Validate and show results
    validate_results

    # Final log
    log "INFO" "Orchestrator completed with status: $overall_status"

    echo ""
    echo "Full logs: $LOG_FILE"
    echo ""

    return $overall_status
}

# Run main
main "$@"
