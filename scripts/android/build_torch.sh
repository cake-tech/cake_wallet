#!/bin/bash
set -x -e
cd "$(dirname "$0")"

DEFAULT_TARGETS=(
  "aarch64-linux-android"
  "armv7a-linux-androideabi"
  "x86_64-linux-android"
)

if [ "$#" -gt 0 ]; then
  TARGETS=("$@")
else
  TARGETS=("${DEFAULT_TARGETS[@]}")
fi

../prepare_torch.sh

cd ../torch_dart

./build.sh "${TARGETS[@]}"
