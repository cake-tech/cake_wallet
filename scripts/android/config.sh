#!/bin/sh

export API=21
export WORKDIR=/opt/android
export ANDROID_NDK_ZIP=${WORKDIR}/android-ndk-r20b.zip
export ANDROID_NDK_ROOT=${WORKDIR}/android-ndk-r20b
export ANDROID_NDK_HOME=$ANDROID_NDK_ROOT
export TOOLCHAIN_DIR="${ANDROID_NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64"

case :${PATH:=${TOOLCHAIN_DIR}/bin}: in
(*:"${TOOLCHAIN_DIR}/bin":*) ;; (*)
    export PATH=${TOOLCHAIN_DIR}/bin:$PATH
esac;
