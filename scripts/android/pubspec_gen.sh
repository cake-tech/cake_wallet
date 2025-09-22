#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

GEN_DESC="$REPO_ROOT/pubspec_description.yaml"
GEN_MAIN="$REPO_ROOT/tool/generate_pubspec.dart"
CFG_MAIN="$REPO_ROOT/tool/configure.dart"

# If the generation tooling isn't present, skip gracefully.
if [ ! -f "$GEN_MAIN" ] || [ ! -f "$GEN_DESC" ]; then
  echo "pubspec_gen: generation files not found; skipping."
  echo "  Missing: $GEN_MAIN or $GEN_DESC"
  exit 0
fi

# Run configure step if it exists (optional)
if [ -f "$CFG_MAIN" ]; then
  ( cd "$REPO_ROOT" && dart "$CFG_MAIN" )
fi

# Generate pubspec.yaml
( cd "$REPO_ROOT" && dart "$GEN_MAIN" "$GEN_DESC" )

echo "pubspec_gen: completed."
