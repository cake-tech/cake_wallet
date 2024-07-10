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

if [[ ! "x$RUNNER_OS" == "x" ]];
then
    REMOVE_CACHES=ON
fi

# NOTE: -j1 is intentional. Otherwise you will run into weird behaviour on macos
if [[ ! "x$USE_DOCKER" == "x" ]];
then
    for COIN in monero wownero;
    do
        pushd ../monero_c
            docker run --platform linux/amd64 -v$HOME/.cache/ccache:/root/.ccache -v$PWD:$PWD -w $PWD --rm -it git.mrcyjanek.net/mrcyjanek/debian:buster bash -c "git config --global --add safe.directory '*'; apt update; apt install -y ccache gcc g++ libtinfo5 gperf; ./build_single.sh ${COIN} x86_64-linux-android $NPROC"
            # docker run --platform linux/amd64 -v$PWD:$PWD -w $PWD --rm -it git.mrcyjanek.net/mrcyjanek/debian:buster bash -c "git config --global --add safe.directory '*'; apt update; apt install -y ccache gcc g++ libtinfo5 gperf; ./build_single.sh ${COIN} i686-linux-android $NPROC"
            docker run --platform linux/amd64 -v$HOME/.cache/ccache:/root/.ccache -v$PWD:$PWD -w $PWD --rm -it git.mrcyjanek.net/mrcyjanek/debian:buster bash -c "git config --global --add safe.directory '*'; apt update; apt install -y ccache gcc g++ libtinfo5 gperf; ./build_single.sh ${COIN} armv7a-linux-androideabi $NPROC"
            docker run --platform linux/amd64 -v$HOME/.cache/ccache:/root/.ccache -v$PWD:$PWD -w $PWD --rm -it git.mrcyjanek.net/mrcyjanek/debian:buster bash -c "git config --global --add safe.directory '*'; apt update; apt install -y ccache gcc g++ libtinfo5 gperf; ./build_single.sh ${COIN} aarch64-linux-android $NPROC"
        popd
    done
else
    for COIN in monero wownero;
    do
        pushd ../monero_c
            env -i ./build_single.sh ${COIN} x86_64-linux-android $NPROC
            [[ ! "x$REMOVE_CACHES" == "x" ]] && rm -rf ${COIN}/contrib/depends/x86_64-linux-android
            # ./build_single.sh ${COIN} i686-linux-android $NPROC
            # [[ ! "x$REMOVE_CACHES" == "x" ]] && rm -rf ${COIN}/contrib/depends/i686-linux-android
            env -i ./build_single.sh ${COIN} armv7a-linux-androideabi $NPROC
            [[ ! "x$REMOVE_CACHES" == "x" ]] && rm -rf ${COIN}/contrib/depends/armv7a-linux-androideabi
            env -i ./build_single.sh ${COIN} aarch64-linux-android $NPROC
            [[ ! "x$REMOVE_CACHES" == "x" ]] && rm -rf ${COIN}/contrib/depends/aarch64-linux-android

        popd
        unxz -f ../monero_c/release/${COIN}/x86_64-linux-android_libwallet2_api_c.so.xz

        unxz -f ../monero_c/release/${COIN}/armv7a-linux-androideabi_libwallet2_api_c.so.xz

        unxz -f ../monero_c/release/${COIN}/aarch64-linux-android_libwallet2_api_c.so.xz
        [[ ! "x$REMOVE_CACHES" == "x" ]] && rm -rf ${COIN}/contrib/depends/{built,sources}
    done
fi
