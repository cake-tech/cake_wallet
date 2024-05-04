#!/bin/sh

. ./config.sh
# ./install_missing_headers.sh
# ./build_openssl.sh
# ./build_boost.sh
# ./build_sodium.sh
# ./build_zmq.sh
# ./build_unbound.sh

set -x -e

cd "$(dirname "$0")"

NPROC="-j$(nproc)"

../prepare_moneroc.sh

# NOTE: -j1 is intentional. Otherwise you will run into weird behaviour on macos
if [[ ! "x$USE_DOCKER" == "x" ]];
then
    for COIN in monero;
    do
        pushd ../monero_c
            echo "unsupported!"
            exit 1
        popd
    done
else
    for COIN in monero;
    do
        pushd ../monero_c
            ./build_single.sh ${COIN} host-apple-ios $NPROC
        popd
    done
fi

unxz -f ../monero_c/release/monero/host-apple-ios_libwallet2_api_c.dylib.xz
# unxz -f ../monero_c/release/wownero/host-apple-ios_libwallet2_api_c.dylib.xz
