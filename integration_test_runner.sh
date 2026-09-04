#!/bin/bash

set -euo pipefail

# Runner params/knobs, all overridable from the environment:
#   SUITE_DIR             directory to collect *_test.dart suites from, or a single suite file
#                         (default integration_test/suites)
#   TEST_TIER             tier0, tier1 or all, narrows SUITE_DIR to a tier subdirectory
#   PLATFORM              android, linux or auto, picks the between-suite data reset
#   ANDROID_APP_ID        package cleared between suites on android (default read from android/app.properties)
#   PREBUILT_APK          prebuilt apk passed to flutter drive, its dart defines are already baked in
#   EXTRA_DART_DEFINES    semicolon separated KEY=VALUE pairs
#   FLUTTER_DEVICE        device id passed to flutter drive, needed when several devices are attached
#   TEST_TIMEOUT          per-attempt timeout in seconds (default 900)
#   RETRY_COUNT           retries per suite after a failure (default 1)
#   MAX_VOID_ATTEMPTS     extra attempts when the driver never attached (default 2)
#   MAX_TOTAL_VOID_ATTEMPTS  give up on the whole run after this many, the environment is broken (default 4)
#   REMOVE_DATA_DIRECTORY set to N to keep app data between suites (default wipes it)
#   SUMMARY_FILE          path to write a key=value summary of the run to, for reporting
#   VOID_GRACE            seconds to let a driver that cannot attach recover before the
#                         attempt is ended early (default 60)

SUITE_DIR=${SUITE_DIR:-integration_test/suites}
TEST_TIER=${TEST_TIER:-all}
PLATFORM=${PLATFORM:-auto}
TEST_TIMEOUT=${TEST_TIMEOUT:-900}
RETRY_COUNT=${RETRY_COUNT:-1}
MAX_VOID_ATTEMPTS=${MAX_VOID_ATTEMPTS:-2}
MAX_TOTAL_VOID_ATTEMPTS=${MAX_TOTAL_VOID_ATTEMPTS:-4}
REMOVE_DATA_DIRECTORY=${REMOVE_DATA_DIRECTORY:-Y}
EXTRA_DART_DEFINES=${EXTRA_DART_DEFINES:-}
SUMMARY_FILE=${SUMMARY_FILE:-}
VOID_GRACE=${VOID_GRACE:-60}

# Using this to capture as many of these annoying flutter drive errors as possible, 
# so we can handle them, and the test doesn't just hang forever
VOID_MARKERS="unusually long time to connect to the VM|taking unusually long time to initialize|Service has disappeared|Flutter Driver extension is taking a long time to become available"
PREBUILT_APK=${PREBUILT_APK:-}

# Linux desktop data directories to wipe between suites
DATA_DIRS=(
    "$HOME/.local/share/com.example.cake_wallet"
    "$HOME/Documents/cake_wallet"
    "$HOME/.config/cake_wallet"
)

targets=()
passed_tests=()
failed_tests=()
funds_results=()
total_void_attempts=0

cleanup() {
    echo "Received interrupt signal, cleaning up..."
    exit 1
}

trap cleanup SIGINT SIGTERM

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >&2
}

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

resolve_platform() {
    if [[ "$PLATFORM" != "auto" ]]; then
        return
    fi

    if command -v adb > /dev/null 2>&1 && adb devices 2>/dev/null | grep -q "device$"; then
        PLATFORM="android"
    else
        PLATFORM="linux"
    fi

    log "Resolved platform: $PLATFORM"
}

resolve_android_app_id() {
    if [[ -n "${ANDROID_APP_ID:-}" ]]; then
        return
    fi

    if [[ -f "android/app.properties" ]]; then
        ANDROID_APP_ID=$(grep '^id=' android/app.properties | cut -d'=' -f2)
    fi

    ANDROID_APP_ID=${ANDROID_APP_ID:-com.cakewallet.cake_wallet}
}

restart_adb() {
    if [[ "$PLATFORM" != "android" ]]; then
        return
    fi

    bounded 30 adb kill-server
    bounded 30 adb start-server
    bounded 60 adb wait-for-device

    if ! bounded 30 adb devices | grep -q "device$"; then
        error "No device is attached after restarting adb"
        return 1
    fi
}

bounded() {
    local limit="$1"
    shift

    if command -v timeout > /dev/null 2>&1; then
        timeout "$limit" "$@" 2>/dev/null || return 1
    elif command -v perl > /dev/null 2>&1; then
        perl -e 'alarm shift; exec @ARGV' "$limit" "$@" 2>/dev/null || return 1
    else
        "$@" 2>/dev/null || return 1
    fi
}

capture_failure_logcat() {
    local test_name="$1"

    if [[ "$PLATFORM" != "android" ]]; then
        return
    fi

    echo "===== logcat after failed attempt: $test_name ====="
    bounded 60 adb logcat -d -t 400 || echo "logcat unavailable"
    echo "===== end logcat ====="
}

clean_data_directories() {
    if [[ "$REMOVE_DATA_DIRECTORY" != "Y" ]]; then
        return
    fi

    log "Cleaning app data..."

    if [[ "$PLATFORM" == "android" ]]; then
        if [[ "$ANDROID_APP_ID" != *".test_"* ]]; then
            error "Refusing to clear $ANDROID_APP_ID, it is not a test build. Rename the app first: printf 'id=com.cakewallet.test_local\\nname=local\\n' > android/app.properties"
        fi

        adb shell pm clear "$ANDROID_APP_ID" > /dev/null 2>&1 || log "pm clear skipped, $ANDROID_APP_ID not installed yet"
        return
    fi

    for dir in "${DATA_DIRS[@]}"; do
        if [[ -d "$dir" ]]; then
            rm -rf "$dir" || error "Failed to remove $dir"
        fi
    done
}

build_drive_command() {
    drive_command=(flutter drive --driver=test_driver/integration_test.dart --dart-define=CI_BUILD=true)

    if [[ -n "${FLUTTER_DEVICE:-}" ]]; then
        drive_command+=("-d" "$FLUTTER_DEVICE")
    fi

    if [[ -n "$PREBUILT_APK" ]]; then
        drive_command+=("--use-application-binary=$PREBUILT_APK")
    fi

    if [[ -n "$EXTRA_DART_DEFINES" ]]; then
        IFS=';' read -ra defines <<< "$EXTRA_DART_DEFINES"
        for define in "${defines[@]}"; do
            drive_command+=("--dart-define=$define")
        done
    fi

    if command -v timeout > /dev/null 2>&1; then
        drive_command=(timeout "$TEST_TIMEOUT" "${drive_command[@]}")
    elif command -v perl > /dev/null 2>&1; then
        drive_command=(perl -e 'alarm shift; exec @ARGV' "$TEST_TIMEOUT" "${drive_command[@]}")
    fi
}

end_process_tree() {
    local root="$1" signal="$2"
    local child

    for child in $(pgrep -P "$root" 2>/dev/null); do
        end_process_tree "$child" "$signal"
    done

    kill "-$signal" "$root" 2>/dev/null || true
}

watch_for_dead_driver() {
    local log_file="$1" drive_pid="$2"
    local marker_seen=0

    while kill -0 "$drive_pid" 2>/dev/null; do
        if (( marker_seen == 0 )) && grep -qE "$VOID_MARKERS" "$log_file" 2>/dev/null; then
            marker_seen=$(date +%s)
            log "Driver is struggling to attach, giving it ${VOID_GRACE}s to recover"
        fi

        if (( marker_seen > 0 )) && (( $(date +%s) - marker_seen >= VOID_GRACE )); then
            log "Driver never attached within ${VOID_GRACE}s, ending this attempt early"

            end_process_tree "$drive_pid" TERM
            sleep 5
            end_process_tree "$drive_pid" KILL

            return 0
        fi

        sleep 5
    done
}

collect_funds_results() {
    local log_file="$1"
    local line

    while IFS= read -r line; do
        funds_results+=("$line")
    done < <(sed -n 's/.*FUNDS_RESULT|//p' "$log_file" | sort -u)
}

run_test() {
    local test_file="$1"
    local test_name=$(basename "$test_file" .dart)
    local retry_count=0
    local void_attempts=0

    while (( retry_count <= RETRY_COUNT )); do
        log "Running test: $test_name (attempt $((retry_count + 1)))"

        clean_data_directories

        local start_time=$(date +%s)
        local attempt_log
        attempt_log=$(mktemp)

        "${drive_command[@]}" --target="$test_file" > >(tee "$attempt_log") 2>&1 &
        local drive_pid=$!

        watch_for_dead_driver "$attempt_log" "$drive_pid" &
        local watchdog_pid=$!
        disown "$watchdog_pid" 2>/dev/null || true

        local attempt_status=0
        wait "$drive_pid" 2>/dev/null || attempt_status=$?

        kill "$watchdog_pid" 2>/dev/null || true

        if (( attempt_status == 0 )); then
            local duration=$(( $(date +%s) - start_time ))

            log "PASS: $test_name ($(format_duration $duration))"
            passed_tests+=("$test_name|$duration")
            collect_funds_results "$attempt_log"
            rm -f "$attempt_log"
            return 0
        else
            local duration=$(( $(date +%s) - start_time ))

            local attempt_was_void=N
            if grep -qE "$VOID_MARKERS" "$attempt_log"; then
                attempt_was_void=Y
            fi

            collect_funds_results "$attempt_log"

            rm -f "$attempt_log"

            log "FAIL: $test_name ($(format_duration $duration))"

            capture_failure_logcat "$test_name"

            if [[ "$attempt_was_void" == "Y" ]]; then
                total_void_attempts=$((total_void_attempts + 1))

                if (( total_void_attempts > MAX_TOTAL_VOID_ATTEMPTS )); then
                    error "The flutter driver failed to attach $total_void_attempts times, the emulator or adb is broken"
                    failed_tests+=("$test_name|$duration|void")
                    return 1
                fi
            fi

            if [[ "$attempt_was_void" == "Y" ]] && (( void_attempts < MAX_VOID_ATTEMPTS )); then
                log "Driver never attached to the app, retrying without spending a retry"
                void_attempts=$((void_attempts + 1))

                if ! restart_adb; then
                    error "Could not bring adb back, aborting this suite"
                    failed_tests+=("$test_name|$duration|void")
                    return 1
                fi

                sleep 5
            elif (( retry_count < RETRY_COUNT )); then
                log "Retrying test: $test_name"
                retry_count=$((retry_count + 1))
                sleep 5
            else
                local fail_reason="test"
                [[ "$attempt_was_void" == "Y" ]] && fail_reason="void"

                failed_tests+=("$test_name|$duration|$fail_reason")
                return 1
            fi
        fi
    done
}

write_github_summary() {
    if [[ -z "${GITHUB_STEP_SUMMARY:-}" ]]; then
        return
    fi

    {
        echo "### Integration tests ($SUITE_DIR, tier: $TEST_TIER)"
        echo ""
        echo "| Suite | Result | Duration |"
        echo "|---|---|---|"
        for entry in "${passed_tests[@]+"${passed_tests[@]}"}"; do
            echo "| ${entry%%|*} | pass | $(format_duration "${entry##*|}") |"
        done
        for entry in "${failed_tests[@]+"${failed_tests[@]}"}"; do
            local rest="${entry#*|}"
            echo "| ${entry%%|*} | ${rest#*|} | $(format_duration "${rest%%|*}") |"
        done
    } >> "$GITHUB_STEP_SUMMARY"
}

write_summary_file() {
    if [[ -z "$SUMMARY_FILE" ]]; then
        return
    fi

    {
        echo "tier=$TEST_TIER"
        echo "total=${#targets[@]}"
        echo "passed=${#passed_tests[@]}"
        echo "failed=${#failed_tests[@]}"
        echo "duration=$1"
        for entry in "${passed_tests[@]+"${passed_tests[@]}"}"; do
            echo "pass=$entry"
        done
        for entry in "${failed_tests[@]+"${failed_tests[@]}"}"; do
            echo "fail=$entry"
        done
        for entry in "${funds_results[@]+"${funds_results[@]}"}"; do
            echo "chain=$entry"
        done
    } > "$SUMMARY_FILE"
}

main() {
    log "Starting integration test runner"

    local search_dir="$SUITE_DIR"
    if [[ "$TEST_TIER" != "all" ]]; then
        search_dir="$SUITE_DIR/$TEST_TIER"
    fi

    if [[ -f "$SUITE_DIR" ]]; then
        search_dir="$SUITE_DIR"
    elif [[ ! -d "$search_dir" ]]; then
        error "Suite directory not found: $search_dir"
        exit 1
    fi

    resolve_platform
    resolve_android_app_id
    build_drive_command

    log "Configuration: SUITE_DIR=$search_dir PLATFORM=$PLATFORM RETRY_COUNT=$RETRY_COUNT"

    if [[ -f "$search_dir" ]]; then
        targets+=("$search_dir")
    else
        while IFS= read -r -d $'\0' file; do
            targets+=("$file")
        done < <(find "$search_dir" -name "*_test.dart" -type f -print0 | sort -z)
    fi

    if (( ${#targets[@]} == 0 )); then
        error "No test files found in $search_dir"
        exit 1
    fi

    log "Found ${#targets[@]} test files"

    local overall_start_time=$(date +%s)

    for target in "${targets[@]}"; do
        run_test "$target" || true
    done

    local total_duration=$(( $(date +%s) - overall_start_time ))

    echo -e "\n===== Test Summary ====="
    echo "Total tests: ${#targets[@]}"
    echo "Passed: ${#passed_tests[@]}"
    echo "Failed: ${#failed_tests[@]}"
    echo "Total duration: $(format_duration $total_duration)"

    if (( ${#passed_tests[@]} > 0 )); then
        echo -e "\nPassed Tests:"
        for entry in "${passed_tests[@]}"; do
            echo "  - ${entry%%|*} ($(format_duration "${entry##*|}"))"
        done
    fi

    write_github_summary
    write_summary_file "$total_duration"

    if (( ${#failed_tests[@]} > 0 )); then
        echo -e "\nFailed Tests:"
        local rest
        for entry in "${failed_tests[@]}"; do
            rest="${entry#*|}"
            echo "  - ${entry%%|*} ($(format_duration "${rest%%|*}"), ${rest#*|})"
        done
        exit 1
    fi

    echo -e "\nAll tests passed successfully!"
}

main "$@"
