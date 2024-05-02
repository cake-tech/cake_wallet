#!/bin/bash

# Usage: env USE_DOCKER= ./build_all.sh 

set -x -e

cd "$(dirname "$0")"

NPROC="-j$(nproc)"

if [[ "x$(uname)" == "xDarwin" ]];
then
    USE_DOCKER="ON"
    NPROC="-j1"
fi

../prepare_moneroc.sh

# NOTE: -j1 is intentional. Otherwise you will run into weird behaviour on macos
if [[ ! "x$USE_DOCKER" == "x" ]];
then
    for COIN in monero;
    do
        pushd ../monero_c
            docker run --platform linux/amd64 -v$HOME/.cache/ccache:/root/.ccache -v$PWD:$PWD -w $PWD --rm -it git.mrcyjanek.net/mrcyjanek/debian:buster bash -c "git config --global --add safe.directory '*'; apt update; apt install -y ccache gcc g++ libtinfo5 gperf; ./build_single.sh ${COIN} x86_64-linux-android $NPROC"
            # docker run --platform linux/amd64 -v$PWD:$PWD -w $PWD --rm -it git.mrcyjanek.net/mrcyjanek/debian:buster bash -c "git config --global --add safe.directory '*'; apt update; apt install -y ccache gcc g++ libtinfo5 gperf; ./build_single.sh ${COIN} i686-linux-android $NPROC"
            docker run --platform linux/amd64 -v$HOME/.cache/ccache:/root/.ccache -v$PWD:$PWD -w $PWD --rm -it git.mrcyjanek.net/mrcyjanek/debian:buster bash -c "git config --global --add safe.directory '*'; apt update; apt install -y ccache gcc g++ libtinfo5 gperf; ./build_single.sh ${COIN} arm-linux-androideabi $NPROC"
            docker run --platform linux/amd64 -v$HOME/.cache/ccache:/root/.ccache -v$PWD:$PWD -w $PWD --rm -it git.mrcyjanek.net/mrcyjanek/debian:buster bash -c "git config --global --add safe.directory '*'; apt update; apt install -y ccache gcc g++ libtinfo5 gperf; ./build_single.sh ${COIN} aarch64-linux-android $NPROC"
        popd
    done
else
    for COIN in monero;
    do
        pushd ../monero_c
            ./build_single.sh ${COIN} x86_64-linux-android $NPROC
            # ./build_single.sh ${COIN} i686-linux-android $NPROC
            ./build_single.sh ${COIN} arm-linux-androideabi $NPROC
            ./build_single.sh ${COIN} aarch64-linux-android $NPROC
        popd
    done
fi

unxz -f ../monero_c/release/monero/x86_64-linux-android_libwallet2_api_c.so.xz
# unxz -f ../monero_c/release/wownero/x86_64-linux-android_libwallet2_api_c.so.xz
unxz -f ../monero_c/release/monero/arm-linux-androideabi_libwallet2_api_c.so.xz
# unxz -f ../monero_c/release/wownero/arm-linux-androideabi_libwallet2_api_c.so.xz
unxz -f ../monero_c/release/monero/aarch64-linux-android_libwallet2_api_c.so.xz
# unxz -f ../monero_c/release/wownero/aarch64-linux-android_libwallet2_api_c.so.xz