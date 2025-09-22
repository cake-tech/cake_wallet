#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Where to read icons from; allow override
: "${APP_ICON_SRC_DIR:="$REPO_ROOT/assets/images"}"
DEST_RES_DIR="$REPO_ROOT/android/app/src/main/res/drawable"

# Safety: never allow root or empty as source
if [ -z "${APP_ICON_SRC_DIR:-}" ] || [ "$APP_ICON_SRC_DIR" = "/" ] || [ "$APP_ICON_SRC_DIR" = "/." ]; then
  echo "Refusing to run: APP_ICON_SRC_DIR is invalid: '$APP_ICON_SRC_DIR'"
  exit 1
fi

mkdir -p "$DEST_RES_DIR"

# Pick icon file(s). Allow override via APP_ICON_FILE, otherwise use common names.
ICON_SRC="${APP_ICON_FILE:-$APP_ICON_SRC_DIR/ic_launcher.png}"
if [ ! -f "$ICON_SRC" ]; then
  ICON_SRC="$APP_ICON_SRC_DIR/app_logo.png"
fi
if [ ! -f "$ICON_SRC" ]; then
  echo "No icon found. Expected one of:
  - $APP_ICON_SRC_DIR/ic_launcher.png
  - $APP_ICON_SRC_DIR/app_logo.png
Set APP_ICON_FILE or APP_ICON_SRC_DIR appropriately."
  exit 1
fi

# Install the icon as both names the project expects
install -m 0644 "$ICON_SRC" "$DEST_RES_DIR/ic_launcher.png"
install -m 0644 "$ICON_SRC" "$DEST_RES_DIR/app_logo.png"

echo "Icons installed to: $DEST_RES_DIR"
