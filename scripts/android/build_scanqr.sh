#!/bin/bash
set -x -e

cd "$(dirname "$0")"

../prepare_scanqr.sh

JNI_LIBS="$(cd ../.. && pwd)/android/app/src/main/jniLibs"

if [[ -n "${ANDROID_NDK_VERSION:-}" && -n "${ANDROID_HOME:-}" ]]; then
    export ANDROID_NDK="${ANDROID_HOME}/ndk/${ANDROID_NDK_VERSION}"
fi

pushd ../scanqr_c_gozxing
    make android-arm64-v8a android-armeabi-v7a android-x86_64 JNI_LIBS="${JNI_LIBS}"
popd
