#!/usr/bin/env bash
set -euo pipefail
if [ -z "${APP_ANDROID_TYPE:-}" ]; then
  echo "Please set APP_ANDROID_TYPE"
  exit 1
fi
SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "${SCRIPT_DIR}/app_properties.sh"
bash "${SCRIPT_DIR}/app_icon.sh"
bash "${SCRIPT_DIR}/pubspec_gen.sh"
bash "${SCRIPT_DIR}/manifest.sh" true
bash "${SCRIPT_DIR}/inject_app_details.sh"
