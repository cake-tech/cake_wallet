#!/bin/bash
set -x -e
cd "$(dirname "$0")"

DEFAULT_TARGETS=(
  "aarch64-apple-ios-simulator"
  "aarch64-apple-ios"
  "aarch64-apple-darwin"
  "x86_64-apple-darwin"
)

if [ "$#" -gt 0 ]; then
  TARGETS=("$@")
else
  TARGETS=("${DEFAULT_TARGETS[@]}")
fi

../prepare_torch.sh

cd ../torch_dart

./build.sh "${TARGETS[@]}"
