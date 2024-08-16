#!/bin/bash


. ./config.sh


set -x -e

cd "$(dirname "$0")"

NPROC="-j$(nproc)"

../prepare_moneroc.sh

for COIN in monero wownero;
do
    pushd ../monero_c
        ./build_single.sh ${COIN} $(gcc -dumpmachine) $NPROC
    popd
    unxz -f ../monero_c/release/${COIN}/$(gcc -dumpmachine)_libwallet2_api_c.so.xz
done
