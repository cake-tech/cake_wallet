#!/bin/sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/functions.sh"

. ./config.sh
# ./install_missing_headers.sh
# ./build_openssl.sh
# ./build_boost.sh
# ./build_sodium.sh
# ./build_zmq.sh
# ./build_unbound.sh

set -x -e

cd "$(dirname "$0")"

../prepare_moneroc.sh

for COIN in monero wownero zano;
do
    pushd ../monero_c
        if [[ -f "release/${COIN}/aarch64-apple-ios_libwallet2_api_c.dylib" ]];
        then
            echo "file exist, not building monero_c for ${COIN}/aarch64-apple-ios.";
        else
            ./build_single.sh ${COIN} aarch64-apple-ios -j$MAKE_JOB_COUNT
            unxz -f ../monero_c/release/${COIN}/aarch64-apple-ios_libwallet2_api_c.dylib.xz
        fi
    popd
done
