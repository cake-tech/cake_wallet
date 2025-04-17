#!/bin/bash

FUZZER_DATA_DIR="./wallet_fuzzer_data"

clear_screen() {
    clear
}

print_header() {
    local col_width=$1
    shift
    
    printf "%-${col_width}s" "OPERATION"
    for device in "$@"; do
        printf "| %-15s " "$(basename "$device")"
    done
    echo
    
    # Print separator line
    printf "%${col_width}s" | tr ' ' '-'
    for ((i=1; i<=$#; i++)); do
        printf "%s" "+-----------------"
    done
    echo
}

display_stats() {
    clear_screen
    
    echo "=== WALLET FUZZER STATISTICS === (refreshes every 5 seconds)"
    echo "Last update: $(date)"
    echo
    
    device_dirs=($FUZZER_DATA_DIR/*)
    
    if [ ${#device_dirs[@]} -eq 0 ]; then
        echo "No device data found in $FUZZER_DATA_DIR"
        return
    fi
    
    operations=()
    for device in "${device_dirs[@]}"; do
        if [ -f "$device/fuzzer_stats.json" ]; then
            if command -v jq &>/dev/null; then
                device_ops=$(jq -r 'keys[]' "$device/fuzzer_stats.json" 2>/dev/null)
                for op in $device_ops; do
                    if [[ ! " ${operations[@]} " =~ " ${op} " ]]; then
                        operations+=("$op")
                    fi
                done
            fi
        fi
    done
    
    IFS=$'\n' sorted_operations=($(sort <<<"${operations[*]}"))
    unset IFS
    
    col_width=20
    for op in "${sorted_operations[@]}"; do
        if [ ${#op} -gt $col_width ]; then
            col_width=${#op}
        fi
    done
    col_width=$((col_width + 5))
    
    print_header $col_width "${device_dirs[@]}"
    
    for op in "${sorted_operations[@]}"; do
        printf "%-${col_width}s" "$op"
        
        for device in "${device_dirs[@]}"; do
            if [ -f "$device/fuzzer_stats.json" ] && command -v jq &>/dev/null; then
                value=$(jq -r ".[\"$op\"] // 0" "$device/fuzzer_stats.json" 2>/dev/null)
                if [ -z "$value" ] || [ "$value" = "null" ]; then
                    value=0
                fi
                printf "| %-15s " "$value"
            else
                printf "| %-15s " "N/A"
            fi
        done
        echo
    done
    
    printf "%-${col_width}s" "TOTAL"
    grand_total=0
    for device in "${device_dirs[@]}"; do
        if [ -f "$device/fuzzer_stats.json" ] && command -v jq &>/dev/null; then
            total=$(jq -r 'to_entries | map(.value) | add' "$device/fuzzer_stats.json" 2>/dev/null)
            if [ -z "$total" ] || [ "$total" = "null" ]; then
                total=0
            fi
            printf "| %-15s " "$total"
            grand_total=$((grand_total + total))
        else
            printf "| %-15s " "N/A"
        fi
    done
    echo
    
    echo
    echo "Total operations across all devices: $grand_total"
}

main() {
    trap 'echo "Exiting..."; exit 0' INT
    
    while true; do
        display_stats
        sleep 5
    done
}

if ! command -v jq &>/dev/null; then
    echo "Warning: jq is not installed. This script requires jq to parse JSON data."
    echo "Please install jq with your package manager (e.g., apt, brew, etc.)"
    exit 1
fi

main 