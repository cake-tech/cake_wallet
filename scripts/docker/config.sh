#!/bin/bash

export API=21
export WORKDIR=/opt/android
export ANDROID_NDK_ZIP=${WORKDIR}/android-ndk-r17c.zip
export ANDROID_NDK_ROOT=${WORKDIR}/android-ndk-r17c
export ANDROID_NDK_HOME=$ANDROID_NDK_ROOT
export TOOLCHAIN_DIR="${WORKDIR}/toolchain"
export TOOLCHAIN_BASE_DIR=$TOOLCHAIN_DIR
export ORIGINAL_PATH=$PATH
export THREADS=4
