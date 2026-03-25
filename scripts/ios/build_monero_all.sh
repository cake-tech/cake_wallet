#!/bin/sh
source "$(cd "$(dirname "$0")/.." && pwd)/functions.sh"

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
        ./build_single.sh ${COIN} aarch64-apple-ios -j$MAKE_JOB_COUNT
        ./build_single.sh ${COIN} aarch64-apple-ios-simulator -j$MAKE_JOB_COUNT
    popd
done

./gen_framework.sh
