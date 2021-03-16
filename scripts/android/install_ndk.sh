# /bin/bash

WORKDIR=/opt/android
ANDROID_NDK_ZIP=${WORKDIR}/android-ndk-r17c.zip
ANDROID_NDK_ROOT=${WORKDIR}/android-ndk-r17c
TOOLCHAIN_DIR=${WORKDIR}/toolchain
TOOLCHAIN_A32_DIR=${TOOLCHAIN_DIR}_aarch
TOOLCHAIN_A64_DIR=${TOOLCHAIN_DIR}_aarch64
TOOLCHAIN_x86_DIR=${TOOLCHAIN_DIR}_i686
TOOLCHAIN_x86_64_DIR=${TOOLCHAIN_DIR}_x86_64

wget https://dl.google.com/android/repository/android-ndk-r17c-linux-x86_64.zip -O /opt/android/android-ndk-r17c.zip
unzip /opt/android/android-ndk-r17c.zip -d $WORKDIR
${ANDROID_NDK_ROOT}/build/tools/make_standalone_toolchain.py --arch arm64 --api 21 --install-dir ${TOOLCHAIN_A64_DIR} --stl=libc++
${ANDROID_NDK_ROOT}/build/tools/make_standalone_toolchain.py --arch arm --api 21 --install-dir ${TOOLCHAIN_A32_DIR} --stl=libc++
${ANDROID_NDK_ROOT}/build/tools/make_standalone_toolchain.py --arch x86 --api 21 --install-dir ${TOOLCHAIN_x86_DIR} --stl=libc++
${ANDROID_NDK_ROOT}/build/tools/make_standalone_toolchain.py --arch x86_64 --api 21 --install-dir ${TOOLCHAIN_x86_64_DIR} --stl=libc++
