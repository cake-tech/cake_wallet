#!/bin/bash

TIER="$1"

if [[ -z "${SUITE_DIR_INPUT:-}" ]]; then
  echo "SUITE_DIR_INPUT never reached the emulator script"
  exit 1
fi

KEYS_IMPORTED=""

import_encryption_keys() {
  if [[ -n "$KEYS_IMPORTED" ]]; then
    return
  fi

  gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys 6B3199AD9B3D23B8 || true # konstantin@cakewallet.com
  gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys 35C8DBAFB8D9ACAC || true # cyjan@mrcyjanek.net
  gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys 0126DFF8D54495EB || true # david@cakewallet.com

  if gpg --list-keys 6B3199AD9B3D23B8 > /dev/null 2>&1 &&
     gpg --list-keys 35C8DBAFB8D9ACAC > /dev/null 2>&1 &&
     gpg --list-keys 0126DFF8D54495EB > /dev/null 2>&1; then
    KEYS_IMPORTED=1
  else
    echo "Recipient keys missing from the keyring, the next call retries the import"
  fi
}

encrypt_and_drop() {
  gpg --trust-model always --encrypt --output "$1.gpg" \
    --recipient 6B3199AD9B3D23B8 \
    --recipient 35C8DBAFB8D9ACAC \
    --recipient 0126DFF8D54495EB \
    "$1" || echo "Encrypting $1 failed, discarding it"
  rm -f "$1"
}

bash scripts/ci/emulator_ready.sh

adb shell settings put global window_animation_scale 0.0 || true
adb shell settings put global transition_animation_scale 0.0 || true
adb shell settings put global animator_duration_scale 0.0 || true

echo "===== resources before $TIER ====="
free -h || true
df -h / || true

if [[ "$RECORD_SCREEN" == "true" ]]; then
  echo "Starting chunked screen recording..."
  (i=0; while true; do adb shell screenrecord --time-limit 180 --bit-rate 2000000 "/sdcard/rec_${TIER}_$i.mp4" || break; i=$((i+1)); done) &
  RECORD_LOOP_PID=$!
fi

# Both tiers get one retry. tier1 talks to live nodes and providers, and giving it
# no retry meant a driver that never attached was reported as a failing test.
RETRIES=1

# The step log is public, so a run log that gets encrypted below must not print here.
run_suites() {
  env \
    SUITE_DIR="$SUITE_DIR_INPUT" \
    TEST_TIER="$TIER" \
    EXTRA_DART_DEFINES="$EXTRA_DART_DEFINES_INPUT" \
    TEST_TIMEOUT=600 \
    RETRY_COUNT=$RETRIES \
    PLATFORM=android \
    SUMMARY_FILE="${TIER}_summary.txt" \
    ./integration_test_runner.sh 2>&1
}

set -o pipefail
set +e
if [[ "${ENCRYPT_LOGS:-}" == "true" ]]; then
  run_suites > "${TIER}_run.log"
else
  run_suites | tee "${TIER}_run.log"
fi
TEST_EXIT_CODE=$?
set -e

echo "===== resources after $TIER ====="
free -h || true
df -h / || true

adb logcat -d > "${TIER}_logcat.txt" || true

# A funds run puts real funded seeds on the device and these carry whatever the app
# logs, so they leave the runner the same way the recordings do
if [[ "${ENCRYPT_LOGS:-}" == "true" ]]; then
  import_encryption_keys
  encrypt_and_drop "${TIER}_logcat.txt"
  encrypt_and_drop "${TIER}_run.log"
fi

if [[ -n "${RECORD_LOOP_PID:-}" ]]; then
  echo "Stopping screen recording and encrypting..."
  kill "$RECORD_LOOP_PID" || true
  adb shell killall -INT screenrecord || true
  sleep 5

  mkdir -p recordings
  for f in $(adb shell ls /sdcard/rec_*.mp4 2>/dev/null | tr -d '\r'); do
    adb pull "$f" recordings/ || true
  done

  # Recordings show seed words on screen so they are never uploaded in plaintext
  import_encryption_keys
  for f in recordings/*.mp4; do
    [[ -f "$f" ]] || continue
    encrypt_and_drop "$f"
  done
fi

exit $TEST_EXIT_CODE
