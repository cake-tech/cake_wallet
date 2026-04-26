#!/bin/bash

set -e

CHECK_ONLY=false
TARGET_DIFF="HEAD"

while [[ "$#" -gt 0 ]]; do
    case $1 in
        check) CHECK_ONLY=true; shift ;;
        *) TARGET_DIFF="$1"; shift ;;
    esac
done

if [ $# -eq 0 ]; then
  echo "warning: no target branch provided, cannot reliably determine diff. will only lint uncommitted files."
  echo "recommended to use ./lint.sh [target_branch], for example ./lint.sh dev"
fi

PR_FILES=$(git diff --name-only "$TARGET_DIFF" | grep '\.dart$')

if [ -z "$PR_FILES" ]; then
  echo "you ain't got no diff (nothing lintable since $TARGET_DIFF)"
  exit 0
fi

FAILED=false

if ! dart format --output=none --set-exit-if-changed "$PR_FILES"; then
  FAILED=true
fi

CUSTOM_LINT_LOG=$(mktemp)
DART_LINT_LOG=$(mktemp)

dart run custom_lint > "$CUSTOM_LINT_LOG" 2>&1 || true

dart analyze > "$DART_LINT_LOG" 2>&1 || true

for file in $PR_FILES; do
  if grep -q "$file" "$CUSTOM_LINT_LOG"; then
    grep -C 2 "$file" "$CUSTOM_LINT_LOG"
    FAILED=true
  fi

  if grep -q "$file" "$DART_LINT_LOG"; then
    grep -C 2 "$file" "$DART_LINT_LOG"
    FAILED=true
  fi
done

rm -rf "$CUSTOM_LINT_LOG" "$DART_LINT_LOG"

if [ "$FAILED" = true ]; then
  exit 1
else
  exit 0
fi