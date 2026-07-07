#!/bin/bash
set -x -e
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/functions.sh"

cd "$(dirname "$0")"

if [[ ! "x$(uname)" == "xLinux" ]];
then
    echo "Only Linux hosts can build windows (yes, i know)";
    exit 1
fi

../prepare_moneroc.sh

# export USE_DOCKER="ON"

pushd ../monero_c
    for COIN in monero wownero;
    do
        $SUDO ./build_single.sh ${COIN} x86_64-w64-mingw32 -j$MAKE_JOB_COUNT
        # $SUDO ./build_single.sh ${COIN} i686-w64-mingw32 -j$MAKE_JOB_COUNT
    done
popd