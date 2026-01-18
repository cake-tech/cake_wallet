#!/bin/bash
set -x -e
cd "$(dirname "$0")"

../prepare_zcash.sh

pushd ../zcash_lib
  ./build-scripts/mac/build-mac.sh
popd
