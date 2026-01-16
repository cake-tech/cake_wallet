#!/bin/bash
set -x -e
cd "$(dirname "$0")"

../prepare_zcash.sh

pushd ../zcash_lib
  ./build-scripts/build-linux.sh
popd
