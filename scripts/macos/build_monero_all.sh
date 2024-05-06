#!/bin/sh
set -x -e

cd "$(dirname "$0")"

NPROC="-j$(sysctl -n hw.logicalcpu)"

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
            ./build_single.sh ${COIN} host-apple-darwin $NPROC
        popd
    done
fi

unxz -f ../monero_c/release/monero/host-apple-darwin_libwallet2_api_c.dylib.xz
# unxz -f ../monero_c/release/wownero/host-apple-darwin_libwallet2_api_c.dylib.xz
