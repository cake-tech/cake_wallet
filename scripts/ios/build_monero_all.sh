#!/bin/bash
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/functions.sh"

set -x -e

cd "$(dirname "$0")"

../prepare_moneroc.sh

if [[ -n "${COIN:-}" ]]; then
    COINS=("$COIN")
else
    COINS=(monero wownero zano)
fi

if [[ -n "${TARGET:-}" ]]; then
    TARGETS=("$TARGET")
else
    TARGETS=(aarch64-apple-ios aarch64-apple-ios-simulator)
fi

for COIN in "${COINS[@]}";
do
    pushd ../monero_c
        for target in "${TARGETS[@]}"
        do
            ./build_single.sh ${COIN} $target -j$MAKE_JOB_COUNT
        done
    popd
done

# needs xcodebuild, on linux (ci cache) only the dylibs are produced
if [[ "$(uname)" == "Darwin" ]]; then
    ./gen_framework.sh
fi
