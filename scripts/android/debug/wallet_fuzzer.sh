#!/bin/bash
set -e
APP_PACKAGE="com.cakewallet.cake_wallet"
ACTIVITY="com.cakewallet.cake_wallet.MainActivity"
LAST_FUZZ_FILE="app_flutter/last_fuzz"
STATS_FILE="app_flutter/fuzzer_stats"
LOCAL_FUZZ_DIR="./wallet_fuzzer_data"

function get_devices() {
    adb devices | grep -v "List" | grep -v "^$" | awk '{print $1}'
}

function init_device_dirs() {
    local device_id=$1
    mkdir -p "$LOCAL_FUZZ_DIR/$device_id"
}

function start_app() {
    local device_id=$1
    adb -s $device_id shell am start -n $APP_PACKAGE/$ACTIVITY
    echo "[$device_id] App started at $(date)"
    # adb shell input tap <- you need to generate these commands in order to open the screen and start
    # fuzzing.
    # on your desktop run:
    # ./scripts/android/debug/record_tap.sh
    # and then copy the output into the adb shell input tap commands below.
    # make sure to tap very briefly, otherwise multiple events will be generated.
    sleep 6
    adb -s $device_id shell input tap 435 1982
    sleep 2.596161
    adb -s $device_id shell input tap 532 1920
    sleep 2.583818
    adb -s $device_id shell input tap 594 1973
    sleep 2.549104
    adb -s $device_id shell input tap 539 2072
    sleep 3.529221
    adb -s $device_id shell input tap 979 139
    sleep 3.287868
    adb -s $device_id shell input tap 430 1645
    sleep 2.325175
    adb -s $device_id shell input tap 368 1784
    sleep 2.461983
    adb -s $device_id shell input tap 442 2164
}

function stop_app() {
    local device_id=$1
    adb -s $device_id shell am force-stop $APP_PACKAGE
    echo "[$device_id] App stopped at $(date)"
}

function get_operation_stats() {
    local device_id=$1
    local LOCAL_STATS_FILE="$LOCAL_FUZZ_DIR/$device_id/fuzzer_stats.json"
    local LOCAL_STATS_HISTORY="$LOCAL_FUZZ_DIR/$device_id/stats_history.json"
    
    echo "[$device_id] Pulling operation statistics..."
    
    adb -s $device_id shell run-as $APP_PACKAGE cat $STATS_FILE > $LOCAL_STATS_FILE.new 2>/dev/null
    
    if [ ! -s "$LOCAL_STATS_FILE.new" ]; then
        echo "[$device_id] No operation statistics found or couldn't access file."
        return 0
    fi
    
    if ! jq empty "$LOCAL_STATS_FILE.new" 2>/dev/null; then
        echo "[$device_id] Invalid JSON data received from device"
        cat "$LOCAL_STATS_FILE.new"
        return 1
    fi
    
    if [ ! -f "$LOCAL_STATS_FILE" ]; then
        # First time stats collection
        mv "$LOCAL_STATS_FILE.new" "$LOCAL_STATS_FILE"
        echo "[$device_id] Initial operation statistics recorded:"
        cat "$LOCAL_STATS_FILE" | jq -r 'to_entries | .[] | "\(.key): \(.value)"' 2>/dev/null || echo "Error parsing JSON, raw content: $(cat $LOCAL_STATS_FILE)"
        
        TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
        STATS_CONTENT=$(cat "$LOCAL_STATS_FILE")
        echo "[{\"timestamp\": \"$TIMESTAMP\", \"stats\": $STATS_CONTENT}]" > "$LOCAL_STATS_HISTORY"
        echo "[$device_id] Created initial stats history with timestamp"
        return 0
    fi
    
    echo "[$device_id] Operation statistics changes since last run:"
    
    if command -v jq >/dev/null 2>&1; then
        if ! jq empty "$LOCAL_STATS_FILE" 2>/dev/null; then
            echo "[$device_id] Previous stats file corrupted, creating new baseline"
            mv "$LOCAL_STATS_FILE.new" "$LOCAL_STATS_FILE"
            return 0
        fi
        
        PREV_STATS=$(cat "$LOCAL_STATS_FILE")
        NEW_STATS=$(cat "$LOCAL_STATS_FILE.new")
        
        echo "[$device_id] Operation | Previous | Current | Difference"
        echo "[$device_id] ----------|----------|---------|----------"
        
        ALL_OPS=$(jq -s '.[0] + .[1] | keys | .[]' "$LOCAL_STATS_FILE" "$LOCAL_STATS_FILE.new" | sort | uniq)
        
        for operation in $ALL_OPS; do
            clean_op=$(echo "$operation" | sed 's/^"//;s/"$//')
            
            PREV_COUNT=$(jq -r ".[\"${clean_op}\"] // 0" <<< "$PREV_STATS")
            
            NEW_COUNT=$(jq -r ".[\"${clean_op}\"] // 0" <<< "$NEW_STATS")
            
            DIFF=$((NEW_COUNT - PREV_COUNT))
            
            printf "[$device_id] %-10s | %8d | %7d | %10d\n" "$clean_op" $PREV_COUNT $NEW_COUNT $DIFF
        done
        
        TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
        if [ -f "$LOCAL_STATS_HISTORY" ]; then
            if grep -q "^\[" "$LOCAL_STATS_HISTORY"; then
                TEMP_FILE=$(mktemp)
                jq --arg timestamp "$TIMESTAMP" --argjson stats "$NEW_STATS" \
                    '. + [{"timestamp": $timestamp, "stats": $stats}]' "$LOCAL_STATS_HISTORY" > "$TEMP_FILE"
                mv "$TEMP_FILE" "$LOCAL_STATS_HISTORY"
            else
                TEMP_FILE=$(mktemp)
                echo "[" > "$TEMP_FILE"
                jq --arg timestamp "$TIMESTAMP" --argjson stats "$NEW_STATS" \
                    '{"timestamp": $timestamp, "stats": $stats}' <<< "{}" >> "$TEMP_FILE"
                echo "]" >> "$TEMP_FILE"
                mv "$TEMP_FILE" "$LOCAL_STATS_HISTORY"
            fi
        else
            echo "[{\"timestamp\": \"$TIMESTAMP\", \"stats\": $NEW_STATS}]" > "$LOCAL_STATS_HISTORY"
        fi
    else
        echo "[$device_id] jq not found. Install jq for better statistics display."
        echo "[$device_id] Raw statistics: "
        cat "$LOCAL_STATS_FILE.new"
    fi
    
    mv "$LOCAL_STATS_FILE.new" "$LOCAL_STATS_FILE"
    return 0
}

function display_stats_summary() {
    local device_id=$1
    local LOCAL_STATS_HISTORY="$LOCAL_FUZZ_DIR/$device_id/stats_history.json"
    local LOCAL_FUZZ_HISTORY="$LOCAL_FUZZ_DIR/$device_id/fuzz_history.log"
    
    if [ ! -f "$LOCAL_STATS_HISTORY" ]; then
        echo "[$device_id] No statistics history found."
        return 0
    fi
    
    if command -v jq >/dev/null 2>&1; then
        echo "[$device_id] === Wallet Fuzzer Statistics Summary ==="
        
        if grep -q "^\[" "$LOCAL_STATS_HISTORY"; then
            echo "[$device_id] History contains $(jq 'length' "$LOCAL_STATS_HISTORY") recorded sessions"
            
            FIRST_TS=$(jq -r '.[0].timestamp' "$LOCAL_STATS_HISTORY")
            LAST_TS=$(jq -r '.[-1].timestamp' "$LOCAL_STATS_HISTORY")
            echo "[$device_id] Tracking period: $FIRST_TS to $LAST_TS"
            
            LATEST_STATS=$(jq -r '.[-1].stats' "$LOCAL_STATS_HISTORY")
            
            TOTAL_OPS=$(jq -r 'to_entries | map(.value) | add' <<< "$LATEST_STATS" 2>/dev/null || echo 0)
            if [ "$TOTAL_OPS" = "" ] || [ "$TOTAL_OPS" = "null" ]; then
                TOTAL_OPS=0
            fi
            echo "[$device_id] Grand total operations: $TOTAL_OPS"
            
            echo "[$device_id] Total operations by type:"
            jq -r 'to_entries | .[] | "\(.key): \(.value)"' <<< "$LATEST_STATS" | sort -k2 -nr | while read -r line; do
                echo "[$device_id] $line"
            done
            
            ENTRIES_COUNT=$(jq 'length' "$LOCAL_STATS_HISTORY")
            if [ "$ENTRIES_COUNT" -gt 1 ]; then
                FIRST_DATE=$(date -d "$FIRST_TS" +%s 2>/dev/null || date -j -f "%Y-%m-%d %H:%M:%S" "$FIRST_TS" +%s)
                LAST_DATE=$(date -d "$LAST_TS" +%s 2>/dev/null || date -j -f "%Y-%m-%d %H:%M:%S" "$LAST_TS" +%s)
                DURATION_HOURS=$(( (LAST_DATE - FIRST_DATE) / 3600 ))
                
                if [ "$DURATION_HOURS" -gt 0 ]; then
                    echo "[$device_id] Operations per hour:"
                    jq -r 'to_entries | .[] | "\(.key): \(.value)"' <<< "$LATEST_STATS" | while read -r line; do
                        OP_NAME=$(echo $line | cut -d':' -f1)
                        OP_COUNT=$(echo $line | cut -d':' -f2 | tr -d ' ')
                        OPS_PER_HOUR=$(echo "scale=2; $OP_COUNT / $DURATION_HOURS" | bc)
                        echo "[$device_id] $OP_NAME: $OPS_PER_HOUR"
                    done
                    
                    TOTAL_OPS_PER_HOUR=$(echo "scale=2; $TOTAL_OPS / $DURATION_HOURS" | bc)
                    echo "[$device_id] Total: $TOTAL_OPS_PER_HOUR ops/hour"
                fi
            fi
        else
            echo "[$device_id] History contains 1 recorded session"
            echo "[$device_id] Stats from current session:"
            LATEST_STATS=$(cat "$LOCAL_STATS_HISTORY")
            
            TOTAL_OPS=$(jq -r 'to_entries | map(.value) | add' <<< "$LATEST_STATS" 2>/dev/null || echo 0)
            if [ "$TOTAL_OPS" = "" ] || [ "$TOTAL_OPS" = "null" ]; then
                TOTAL_OPS=0
            fi
            echo "[$device_id] Grand total operations: $TOTAL_OPS"
            
            echo "[$device_id] Total operations by type:"
            jq -r 'to_entries | .[] | "\(.key): \(.value)"' <<< "$LATEST_STATS" | sort -k2 -nr | while read -r line; do
                echo "[$device_id] $line"
            done
        fi
        
        TOTAL_RUNS=$(grep -c "INITIAL" "$LOCAL_FUZZ_HISTORY" 2>/dev/null || echo 0)
        echo "[$device_id] Total runs since tracking began: $TOTAL_RUNS"
    else
        echo "[$device_id] jq not installed. Install jq for statistics summary."
    fi
}

function get_app_data() {
    local device_id=$1
    local LOCAL_FUZZ_FILE="$LOCAL_FUZZ_DIR/$device_id/last_fuzz"
    local LOCAL_FUZZ_HISTORY="$LOCAL_FUZZ_DIR/$device_id/fuzz_history.log"
    
    APP_DATA_DIR=$(adb -s $device_id shell run-as $APP_PACKAGE pwd)
    
    if [ -z "$APP_DATA_DIR" ]; then
        echo "[$device_id] Failed to get app data directory. Make sure app is in debug mode."
        return 1
    fi
    
    adb -s $device_id shell run-as $APP_PACKAGE cat $LAST_FUZZ_FILE > $LOCAL_FUZZ_FILE.new 2>/dev/null
    
    if [ ! -s "$LOCAL_FUZZ_FILE.new" ]; then
        echo "[$device_id] No wallet state information found or couldn't access file."
        return 0
    fi
    
    ENTRY_COUNT=$(wc -l < "$LOCAL_FUZZ_FILE.new")
    echo "[$device_id] Found $ENTRY_COUNT wallet state entries"
    
    if [ ! -f "$LOCAL_FUZZ_FILE" ]; then
        mv "$LOCAL_FUZZ_FILE.new" "$LOCAL_FUZZ_FILE"
        echo "[$device_id] Initial wallet state recorded with $ENTRY_COUNT entries:"
        cat "$LOCAL_FUZZ_FILE" | while read -r line; do
            echo "[$device_id]  - $line"
        done
        echo "$(date): INITIAL: $ENTRY_COUNT entries" >> $LOCAL_FUZZ_HISTORY
        return 0
    fi
    
    PREV_WALLETS=$(awk -F'|' '{print $1}' "$LOCAL_FUZZ_FILE" | sort | uniq)
    NEW_WALLETS=$(awk -F'|' '{print $1}' "$LOCAL_FUZZ_FILE.new" | sort | uniq)
    
    NEW_ONLY_WALLETS=$(comm -13 <(echo "$PREV_WALLETS") <(echo "$NEW_WALLETS"))
    if [ ! -z "$NEW_ONLY_WALLETS" ]; then
        echo "[$device_id] New wallets detected: $NEW_ONLY_WALLETS (normal behavior)"
        echo "[$device_id] New wallet details:"
        for wallet in $NEW_ONLY_WALLETS; do
            (grep "^$wallet|" "$LOCAL_FUZZ_FILE.new" || true) | while read -r line; do
                echo "[$device_id]  - $line"
            done
        done
    fi
    
    MISSING_WALLETS=$(comm -23 <(echo "$PREV_WALLETS") <(echo "$NEW_WALLETS"))
    if [ ! -z "$MISSING_WALLETS" ]; then
        echo "[$device_id] Wallets no longer present: $MISSING_WALLETS"
        echo "$(date): MISSING_WALLETS: $MISSING_WALLETS" >> $LOCAL_FUZZ_HISTORY
    fi
    
    COMMON_WALLETS=$(comm -12 <(echo "$PREV_WALLETS") <(echo "$NEW_WALLETS"))
    
    CORRUPTION_DETECTED=0
    EVIDENCE_DIR="$LOCAL_FUZZ_DIR/$device_id/corruption_$(date +%Y%m%d_%H%M%S)"
    
    if [ ! -z "$COMMON_WALLETS" ]; then
        echo "[$device_id] Checking common wallets for changes: $COMMON_WALLETS"
        
        for wallet in $COMMON_WALLETS; do
            PREV_ENTRIES=$(grep "^$wallet|" "$LOCAL_FUZZ_FILE" || true)
            NEW_ENTRIES=$(grep "^$wallet|" "$LOCAL_FUZZ_FILE.new" || true)
            
            PREV_COUNT=$(echo "$PREV_ENTRIES" | wc -l)
            NEW_COUNT=$(echo "$NEW_ENTRIES" | wc -l)
            
            echo "[$device_id] Wallet $wallet: $PREV_COUNT previous entries, $NEW_COUNT new entries"
            
            if [ $NEW_COUNT -gt $PREV_COUNT ]; then
                echo "[$device_id] Wallet $wallet has $((NEW_COUNT - PREV_COUNT)) new operation(s)"
            fi
            
            PREV_INFO=$(echo "$PREV_ENTRIES" | tail -n1)
            NEW_INFO=$(echo "$NEW_ENTRIES" | tail -n1)
            
            if [ "$PREV_INFO" = "$NEW_INFO" ]; then
                echo "[$device_id] Wallet $wallet is unchanged"
                continue
            fi
            mkdir -p "$EVIDENCE_DIR"
            
            echo "[$device_id] WALLET CHANGED - POTENTIAL CORRUPTION DETECTED"
            echo "[$device_id] Wallet: $wallet" | tee -a "$EVIDENCE_DIR/corruption_details.txt"
            echo "[$device_id] Previous: $PREV_INFO" | tee -a "$EVIDENCE_DIR/corruption_details.txt"
            echo "[$device_id] Current:  $NEW_INFO" | tee -a "$EVIDENCE_DIR/corruption_details.txt"
            CORRUPTION_DETECTED=1
        done
    fi
    
    if [ $CORRUPTION_DETECTED -eq 1 ]; then
        echo "$(date): CORRUPTION_DETECTED" >> $LOCAL_FUZZ_HISTORY
        
        
        cp "$LOCAL_FUZZ_FILE" "$EVIDENCE_DIR/last_fuzz.prev"
        cp "$LOCAL_FUZZ_FILE.new" "$EVIDENCE_DIR/last_fuzz.new"
        
        echo "=== DETAILED COMPARISON $(date) ===" > "$EVIDENCE_DIR/comparison.txt"
        echo "Previous file contents:" >> "$EVIDENCE_DIR/comparison.txt"
        cat "$LOCAL_FUZZ_FILE" >> "$EVIDENCE_DIR/comparison.txt"
        echo -e "\nNew file contents:" >> "$EVIDENCE_DIR/comparison.txt"
        cat "$LOCAL_FUZZ_FILE.new" >> "$EVIDENCE_DIR/comparison.txt"
        echo -e "\nDiff output:" >> "$EVIDENCE_DIR/comparison.txt"
        diff "$LOCAL_FUZZ_FILE" "$LOCAL_FUZZ_FILE.new" >> "$EVIDENCE_DIR/comparison.txt" || true
        
        echo "[$device_id] Pulling all files from app package directory..."
        APP_FILES_DIR="$EVIDENCE_DIR/app_files"
        mkdir -p "$APP_FILES_DIR" || true
        
        FILE_LIST_TMP="$EVIDENCE_DIR/file_list.txt"
        adb -s $device_id shell run-as $APP_PACKAGE "find . -type f | grep -v -E 'cache|no_backup'" > "$FILE_LIST_TMP"
        
        TOTAL_FILES=$(wc -l < "$FILE_LIST_TMP")
        echo "[$device_id] Found $TOTAL_FILES files to process"
        
        FILE_COUNT=0
        OLDIFS="$IFS"
        IFS=$'\n'
        for file_path in $(cat "$FILE_LIST_TMP"); do
            FILE_COUNT=$((FILE_COUNT + 1))
            echo "[$device_id] Processing file $FILE_COUNT/$TOTAL_FILES: $file_path"
            
            rel_dir=$(dirname "$file_path")
            mkdir -p "$APP_FILES_DIR/$rel_dir" || true
            
            dest_file="$APP_FILES_DIR/$file_path"
            adb -s $device_id shell run-as $APP_PACKAGE cat "$file_path" > "$dest_file" 2>/dev/null || echo "[$device_id] Failed to copy $file_path"
        done
        IFS="$OLDIFS"
        
        echo "[$device_id] Evidence saved to $EVIDENCE_DIR"
    fi
    
    mv "$LOCAL_FUZZ_FILE.new" "$LOCAL_FUZZ_FILE"
    
    if [ $CORRUPTION_DETECTED -eq 1 ]; then
        return 1
    else
        return 0
    fi
}

function run_device_test() {
    local device_id=$1
    
    stop_app $device_id
    sleep 2
    
    display_stats_summary $device_id
    
    local error_detected=0
    
    while [ $error_detected -eq 0 ]; do
        start_app $device_id
        RUN_TIME=$((30 + RANDOM % 120))
        echo "[$device_id] Will run for $RUN_TIME seconds"
        sleep $RUN_TIME
        
        stop_app $device_id
        
        get_operation_stats $device_id
        
        get_app_data $device_id
        if [ $? -ne 0 ]; then
            echo "[$device_id] Stopping tests due to potential wallet corruption!"
            error_detected=1
            break
        fi
        
        WAIT_TIME=$((5 + RANDOM % 15))
        echo "[$device_id] Will wait for $WAIT_TIME seconds"
        sleep $WAIT_TIME
    done
    
    echo "[$device_id] Device testing completed"
}

mkdir -p $LOCAL_FUZZ_DIR

DEVICES=$(get_devices)
DEVICE_COUNT=$(echo "$DEVICES" | wc -l)

if [ -z "$DEVICES" ]; then
    echo "No ADB devices connected. Exiting."
    exit 1
fi

echo "Found $DEVICE_COUNT connected device(s):"
echo "$DEVICES" | while read device; do
    echo "- $device"
    init_device_dirs $device
done

for device in $DEVICES; do
    echo "Starting tests on device $device"
    RANDOM_DELAY=$(awk -v min=0.05 -v max=1.00 'BEGIN{srand(); print min+rand()*(max-min)}')
    echo "[$device] Waiting for $RANDOM_DELAY seconds before starting test"
    sleep $RANDOM_DELAY
    run_device_test $device &
done

wait

echo "All device tests completed"