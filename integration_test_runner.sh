#!/bin/bash

# Exit on any error
set -euo pipefail

# Configurations
export DESKTOP_FORCE_MOBILE="Y"
MAX_INACTIVITY=${MAX_INACTIVITY:-180}
MAX_PARALLEL_TESTS=${MAX_PARALLEL_TESTS:-2}
TEST_TIMEOUT=${TEST_TIMEOUT:-600}
RETRY_COUNT=${RETRY_COUNT:-1}

# Data directories to clean
DATA_DIRS=(
    "$HOME/.local/share/com.example.cake_wallet"
    "$HOME/Documents/cake_wallet"
    "$HOME/.config/cake_wallet"
)

# Global state
declare -a targets
declare -a passed_tests
declare -a failed_tests
declare -a test_durations
declare -a test_start_times

# Signal handling
cleanup() {
    echo "🛑 Received interrupt signal, cleaning up..."
    exit 1
}

trap cleanup SIGINT SIGTERM

# Utility functions
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >&2
}

# Format seconds into hours, minutes, seconds
format_duration() {
    local seconds=$1
    local hours=$((seconds / 3600))
    local minutes=$(((seconds % 3600) / 60))
    local secs=$((seconds % 60))

    if (( hours > 0 )); then
        echo "${hours}h ${minutes}m ${secs}s"
    elif (( minutes > 0 )); then
        echo "${minutes}m ${secs}s"
    else
        echo "${secs}s"
    fi
}

clean_data_directories() {
    if [[ "${REMOVE_DATA_DIRECTORY:-}" == "Y" ]]; then
        log "Cleaning data directories..."
        for dir in "${DATA_DIRS[@]}"; do
            if [[ -d "$dir" ]]; then
                rm -rf "$dir" || error "Failed to remove $dir"
            fi
        done
    fi
}

# Run a single test with retry logic
run_test() {
    local test_file="$1"
    local test_name=$(basename "$test_file" .dart)
    local retry_count=0

    while (( retry_count <= RETRY_COUNT )); do
        log "Running test: $test_name (attempt $((retry_count + 1)))"

        # Clean data directories before each attempt
        clean_data_directories

        # Record start time
        local start_time=$(date +%s)
        test_start_times+=("$start_time")

        # Run the test in foreground
        if flutter drive \
            --driver=test_driver/integration_test.dart \
            --target="$test_file" \
            --dart-define=CI_BUILD=true; then
            # Calculate duration
            local end_time=$(date +%s)
            local duration=$((end_time - start_time))
            test_durations+=("$duration")

            log "✅ Test passed: $test_name ($(format_duration $duration))"
            passed_tests+=("$test_name")
            return 0
        else
            # Calculate duration even for failed tests
            local end_time=$(date +%s)
            local duration=$((end_time - start_time))
            test_durations+=("$duration")

            log "❌ Test failed: $test_name ($(format_duration $duration))"

            if (( retry_count < RETRY_COUNT )); then
                log "Retrying test: $test_name"
                retry_count=$((retry_count + 1))
                sleep 5  # Brief pause before retry
            else
                failed_tests+=("$test_name")
                return 1
            fi
        fi
    done
}

# Main execution flow
main() {
    log "Starting integration test runner"
    log "Configuration: RETRY_COUNT=${RETRY_COUNT}"

    # Collect all Dart test files from test_suites directory
    while IFS= read -r -d $'\0' file; do
        targets+=("$file")
    done < <(find integration_test/test_suites -name "*.dart" -type f -print0)

    if [[ $? -ne 0 ]]; then
        error "Failed to find test files"
        exit 1
    fi

    if (( ${#targets[@]} == 0 )); then
        error "No test files found in integration_test/test_suites directory"
        exit 1
    fi

    log "Found ${#targets[@]} test files"

    # Record overall start time
    local overall_start_time=$(date +%s)

    # Run tests sequentially
    for target in "${targets[@]}"; do
        run_test "$target"
    done

    # Calculate total duration
    local overall_end_time=$(date +%s)
    local total_duration=$((overall_end_time - overall_start_time))

    # Generate summary
    echo -e "\n===== Test Summary ====="
    echo "Total tests: ${#targets[@]}"
    echo "Passed: ${#passed_tests[@]}"
    echo "Failed: ${#failed_tests[@]}"
    echo "Total duration: $(format_duration $total_duration)"

    if (( ${#passed_tests[@]} > 0 )); then
        echo -e "\n✅ Passed Tests:"
        for i in $(seq 0 $((${#passed_tests[@]} - 1))); do
            local test_name="${passed_tests[$i]}"
            local duration="${test_durations[$i]}"
            echo "  - $test_name ($(format_duration $duration))"
        done
    fi

    if (( ${#failed_tests[@]} > 0 )); then
        echo -e "\n❌ Failed Tests:"
        for i in $(seq 0 $((${#failed_tests[@]} - 1))); do
            local test_name="${failed_tests[$i]}"
            local duration="${test_durations[$i]}"
            echo "  - $test_name ($(format_duration $duration))"
        done
        exit 1
    else
        echo -e "\n🎉 All tests passed successfully!"
    fi
}

# Run main function
main "$@"
