#!/bin/bash
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/functions.sh"

set -x -e

cd "$(dirname "$0")"

../prepare_moneroc.sh

for COIN in monero wownero;
do
    pushd ../monero_c
        # Determine target architecture based on system architecture
        if [[ $(uname -m) == "arm64" || $(uname -m) == "aarch64" ]]; then
            target="aarch64-linux-gnu"
        else
            target="x86_64-linux-gnu"
        fi

        ./build_single.sh ${COIN} $target -j$MAKE_JOB_COUNT
    popd
done
