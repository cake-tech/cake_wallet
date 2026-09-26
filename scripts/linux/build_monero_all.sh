#!/bin/bash
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/functions.sh"

set -x -e

cd "$(dirname "$0")"

../prepare_moneroc.sh

if [[ -n "${COIN:-}" ]]; then
    COINS=("$COIN")
else
    COINS=(monero wownero)
fi

if [[ -n "${TARGET:-}" ]]; then
    target="$TARGET"
elif [[ $(uname -m) == "arm64" || $(uname -m) == "aarch64" ]]; then
    target="aarch64-linux-gnu"
else
    target="x86_64-linux-gnu"
fi

for COIN in "${COINS[@]}";
do
    pushd ../monero_c
        ./build_single.sh ${COIN} $target -j$MAKE_JOB_COUNT
    popd
done
