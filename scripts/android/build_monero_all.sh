#!/bin/bash
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/functions.sh"

# Usage: env USE_DOCKER= ./build_all.sh

set -x -e

cd "$(dirname "$0")"

../prepare_moneroc.sh

for COIN in monero wownero zano;
do
    pushd ../monero_c
        monero_c_tag=$(git describe --tags)
        for target in {x86_64,aarch64}-linux-android armv7a-linux-androideabi
        do
            if [[ -f "release/${monero_c_tag}/${target}/${COIN}_libwallet2_api_c.so" ]];
            then
                echo "file exist, not building monero_c for ${COIN}/$target.";
            else
                ./build_single.sh ${COIN} $target -j$MAKE_JOB_COUNT
            fi

            case $target in
                x86_64-linux-android)
                    mkdir -p ../../android/app/src/main/jniLibs/x86_64 || true
                    cp ../monero_c/release/${monero_c_tag}/${target}/lib${COIN}_wallet2_api_c.so ../../android/app/src/main/jniLibs/x86_64/
                    ;;
                armv7a-linux-androideabi)
                    mkdir -p ../../android/app/src/main/jniLibs/armeabi-v7a || true
                    cp ../monero_c/release/${monero_c_tag}/${target}/lib${COIN}_wallet2_api_c.so ../../android/app/src/main/jniLibs/armeabi-v7a/
                    ;;
                aarch64-linux-android)
                    mkdir -p ../../android/app/src/main/jniLibs/arm64-v8a || true
                    cp ../monero_c/release/${monero_c_tag}/${target}/lib${COIN}_wallet2_api_c.so ../../android/app/src/main/jniLibs/arm64-v8a/
                    ;;
                *)
                    echo "Unsupported target: $target"
                    exit 1;
            esac
        done
    popd
done
