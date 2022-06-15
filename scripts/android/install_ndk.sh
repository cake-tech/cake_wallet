#!/bin/sh

mkdir build
. ./config.sh
TOOLCHAIN_DIR=${WORKDIR}/toolchain
TOOLCHAIN_A32_DIR=${TOOLCHAIN_DIR}_aarch
TOOLCHAIN_A64_DIR=${TOOLCHAIN_DIR}_aarch64
TOOLCHAIN_x86_DIR=${TOOLCHAIN_DIR}_i686
TOOLCHAIN_x86_64_DIR=${TOOLCHAIN_DIR}_x86_64
ANDROID_NDK_SHA256="8381c440fe61fcbb01e209211ac01b519cd6adf51ab1c2281d5daad6ca4c8c8c"

curl https://dl.google.com/android/repository/android-ndk-r20b-linux-x86_64.zip -o ${ANDROID_NDK_ZIP}
echo $ANDROID_NDK_SHA256 $ANDROID_NDK_ZIP | sha256sum -c || exit 1
unzip $ANDROID_NDK_ZIP -d $WORKDIR

python3 ${ANDROID_NDK_ROOT}/build/tools/make_standalone_toolchain.py --arch arm64 --api $API --install-dir ${TOOLCHAIN_A64_DIR} --stl=libc++
python3 ${ANDROID_NDK_ROOT}/build/tools/make_standalone_toolchain.py --arch arm --api $API --install-dir ${TOOLCHAIN_A32_DIR} --stl=libc++
python3 ${ANDROID_NDK_ROOT}/build/tools/make_standalone_toolchain.py --arch x86 --api $API --install-dir ${TOOLCHAIN_x86_DIR} --stl=libc++
python3 ${ANDROID_NDK_ROOT}/build/tools/make_standalone_toolchain.py --arch x86_64 --api $API --install-dir ${TOOLCHAIN_x86_64_DIR} --stl=libc++
