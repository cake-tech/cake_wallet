#!/bin/bash
# This script extracts the device's screen resolution and the raw touch coordinate maximums,
# listens for a tap event, scales the raw touch coordinates to the screen resolution,
# and then outputs and executes an adb tap command.

screen_info=$(adb shell wm size | ggrep -oP "\d+x\d+")
if [[ -z "$screen_info" ]]; then
  echo "Failed to get screen resolution."
  exit 1
fi

SCREEN_WIDTH=${screen_info%x*}
SCREEN_HEIGHT=${screen_info#*x}
echo "Screen resolution: ${SCREEN_WIDTH}x${SCREEN_HEIGHT}"

echo "Detecting touch input device..."
TOUCH_DEVICE=""

devices_info=$(adb shell getevent -i)
echo "Found input devices:"

while read -r line; do
  if [[ $line =~ ^add\ device\ ([0-9]+):\ (.+) ]]; then
    device_num="${BASH_REMATCH[1]}"
    device_path="${BASH_REMATCH[2]}"
    device_name=$(echo "$devices_info" | ggrep -A 5 "add device $device_num:" | ggrep "name:" | gawk -F'"' '{print $2}')
    echo "  Device $device_num: $device_path ($device_name)"
    
    # Check if device has touch capabilities
    # Look for ABS events 0035 and 0036 which correspond to X and Y coordinates
    touch_info=$(adb shell getevent -pl "$device_path")
    if echo "$touch_info" | ggrep -q "ABS.*0035" && echo "$touch_info" | ggrep -q "ABS.*0036"; then
      TOUCH_DEVICE="$device_path"
      echo "Selected touch device at $TOUCH_DEVICE"
    fi
  fi
done < <(echo "$devices_info" | ggrep "^add device")

if [[ -z "$TOUCH_DEVICE" ]]; then
  echo "Failed to detect touch input device."
  echo "Trying to use the first 'multi_touch' device as fallback..."
  
  while read -r line; do
    if [[ $line =~ ^add\ device\ ([0-9]+):\ (.+) ]]; then
      device_num="${BASH_REMATCH[1]}"
      device_path="${BASH_REMATCH[2]}"
      device_name=$(echo "$devices_info" | ggrep -A 5 "add device $device_num:" | ggrep "name:" | gawk -F'"' '{print $2}')
      
      if [[ "$device_name" == *"multi_touch"* ]]; then
        TOUCH_DEVICE="$device_path"
        echo "Selected fallback touch device at $TOUCH_DEVICE ($device_name)"
        break
      fi
    fi
  done < <(echo "$devices_info" | ggrep "^add device")
fi

if [[ -z "$TOUCH_DEVICE" ]]; then
  echo "No touch device found. Please manually specify the device node as an argument."
  echo "Available devices:"
  echo "$devices_info" | ggrep -A 5 "^add device" | ggrep -E "^add device|name:"
  exit 1
fi

raw_info=$(adb shell getevent -pl "$TOUCH_DEVICE")

# Extract X and Y max values - try multiple ABS codes that could represent X/Y coordinates
extract_max() {
  local raw_info="$1"
  local abs_code="$2"
  
  echo "$raw_info" | gawk -v code="$abs_code" '
    $0 ~ code {
      for(i=1; i<=NF; i++) {
        if($i == "max") {
          print $(i+1)
          exit
        }
      }
    }
  '
}

# Try to find X max from either ABS_MT_POSITION_X or plain X position (0035)
RAW_MAX_X=$(extract_max "$raw_info" "ABS_MT_POSITION_X")
if [[ -z "$RAW_MAX_X" ]]; then
  RAW_MAX_X=$(extract_max "$raw_info" "0035")
fi

# Try to find Y max from either ABS_MT_POSITION_Y or plain Y position (0036)
RAW_MAX_Y=$(extract_max "$raw_info" "ABS_MT_POSITION_Y")
if [[ -z "$RAW_MAX_Y" ]]; then
  RAW_MAX_Y=$(extract_max "$raw_info" "0036")
fi

if [[ -z "$RAW_MAX_X" || -z "$RAW_MAX_Y" ]]; then
  echo "Failed to extract raw maximum values for touch coordinates."
  echo "Using default values for emulator: 32767 x 32767"
  RAW_MAX_X=32767
  RAW_MAX_Y=32767
fi

echo "Raw touch coordinate range: X max=$RAW_MAX_X, Y max=$RAW_MAX_Y"

echo "Waiting for a tap event. Press Ctrl+C to exit..."

adb shell getevent -lt "$TOUCH_DEVICE" | gawk -v sw="$SCREEN_WIDTH" -v sh="$SCREEN_HEIGHT" -v rx="$RAW_MAX_X" -v ry="$RAW_MAX_Y" '
  /ABS_MT_POSITION_X/ || /0035 / {
    # Convert hex raw x-coordinate to a number.
    raw_x = strtonum("0x" $NF)
  }
  /ABS_MT_POSITION_Y/ || /0036 / {
    # Convert hex raw y-coordinate to a number.
    raw_y = strtonum("0x" $NF)
    # Extract the timestamp from the beginning of the line (e.g., "[   43466.939179]")
    if (match($0, /\[ *([0-9]+\.[0-9]+)\]/, arr)) {
       curr_time = arr[1] + 0  # ensure numeric conversion
    }
    # If a previous timestamp exists, compute delay and print sleep command.
    if (prev_time != "") {
       delay = curr_time - prev_time
       # Print a sleep command with the delay (formatted with microsecond precision)
       printf "sleep %.6f\n", delay
    }
    prev_time = curr_time
    # Scale raw coordinates to screen resolution coordinates.
    scaled_x = int(raw_x * sw / rx)
    scaled_y = int(raw_y * sh / ry)
    # Print the input tap command.
    printf "adb -s \$device_id shell input tap %d %d\n", scaled_x, scaled_y
  }
'
