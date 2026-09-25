#!/bin/bash
set -x -e
cd "$(dirname "$0")"

../prepare_pivx.sh

OUTPUT_DIR="$(cd ../../cw_pivx/ios && pwd)/Frameworks" ../pivx_lib/scripts/build_ios.sh
