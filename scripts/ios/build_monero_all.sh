#!/bin/sh

. ./config.sh
# ./install_missing_headers.sh
# ./build_openssl.sh
# ./build_boost.sh
# ./build_sodium.sh
# ./build_zmq.sh
# ./build_unbound.sh
# ./build_decred.sh

set -x -e

cd "$(dirname "$0")"

NPROC="-j$(sysctl -n hw.logicalcpu)"

../prepare_moneroc.sh

for COIN in monero wownero;
do
    pushd ../monero_c
        ./build_single.sh ${COIN} host-apple-ios $NPROC
    popd
done

unxz -f ../monero_c/release/monero/host-apple-ios_libwallet2_api_c.dylib.xz
unxz -f ../monero_c/release/wownero/host-apple-ios_libwallet2_api_c.dylib.xz
