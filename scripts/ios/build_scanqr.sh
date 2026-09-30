#!/bin/bash
set -x -e

cd "$(dirname "$0")"

../prepare_scanqr.sh

pushd ../scanqr_c_gozxing
    make apple
popd
