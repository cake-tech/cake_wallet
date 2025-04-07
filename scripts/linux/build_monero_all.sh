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
        
        if [[ -f "release/${COIN}/${target}_libwallet2_api_c.so" ]];
        then
            echo "file exist, not building monero_c for ${COIN}/$target.";
        else
            ./build_single.sh ${COIN} $target -j$MAKE_JOB_COUNT
            unxz -f ../monero_c/release/${COIN}/${target}_libwallet2_api_c.so.xz
        fi
    popd
done