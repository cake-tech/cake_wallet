#!/usr/bin/env bash
set -euo pipefail

# Require these
: "${APP_ANDROID_TYPE:?Please set APP_ANDROID_TYPE}"
: "${APP_ANDROID_BUNDLE_ID:?Please set APP_ANDROID_BUNDLE_ID}"
: "${APP_ANDROID_NAME:?Please set APP_ANDROID_NAME}"

# Resolve paths robustly
SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

APP_PROPERTIES_PATH="$REPO_ROOT/android/app.properties"

# Ensure parent directory exists
mkdir -p "$(dirname "$APP_PROPERTIES_PATH")"

# Write properties
printf 'id=%s\nname=%s\n' "$APP_ANDROID_BUNDLE_ID" "$APP_ANDROID_NAME" > "$APP_PROPERTIES_PATH"

echo "Wrote $APP_PROPERTIES_PATH"
