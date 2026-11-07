#!/bin/bash
set -x -e
cd "$(dirname "$0")"

../prepare_pivx.sh

OUTPUT_DIR="$(cd ../../cw_pivx/android/src/main && pwd)/jniLibs" ../pivx_lib/scripts/build_android.sh
