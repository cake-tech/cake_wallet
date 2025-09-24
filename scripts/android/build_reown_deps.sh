#!/bin/bash

# NOTE: This script is used to build the reown dependencies for the android app.
# ideally we should be able to get rid of this script when yttrium updates at some point.
# CI uses prebuilds that are provided as-is at https://static.mrcyjanek.net/lfs/cake-yttrium/
# please, do **NOT** use those prebuilds for production.

cd "$(dirname $0)"

set -x -e

if [ ! -e yttrium/.git ]; then
    rm -rf yttrium
    git clone https://github.com/reown-com/yttrium
fi
cd yttrium
# git checkout ed8e8f5af2029406263be5993e484c3a69c1db7a
git reset --hard
git checkout 9f81ab8e0fb879a994392d603b7908b2104d1735
git reset --hard

sed -i.bak "s/-i ''/-i.bak/g" build-kotlin.sh
sed -i.bak "s/--bin uniffi-bindgen generate/-p kotlin-ffi --bin uniffi-bindgen generate/g" build-kotlin.sh
sed -i.bak "s/stat -f%z/echo stat -f%z/g" build-kotlin.sh
sed -i.bak "s/ -t arm64-v8a/ -t arm64-v8a -t x86_64/g" build-kotlin.sh

cargo install cargo-ndk
ENABLE_STRIP=false PROFILE=release bash -x ./build-kotlin.sh

cp target/x86_64-linux-android/release/deps/libuniffi_yttrium.so ../../../android/app/src/main/jniLibs/x86_64/libuniffi_yttrium.so
cp target/aarch64-linux-android/release/deps/libuniffi_yttrium.so ../../../android/app/src/main/jniLibs/arm64-v8a/libuniffi_yttrium.so
cp target/armv7-linux-androideabi/release/deps/libuniffi_yttrium.so ../../../android/app/src/main/jniLibs/armeabi-v7a/libuniffi_yttrium.so