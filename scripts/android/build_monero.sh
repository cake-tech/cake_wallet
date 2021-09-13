#!/bin/sh

. ./config.sh
MONERO_BRANCH=v0.17.2.3-android
MONERO_SRC_DIR=${WORKDIR}/monero
CMAKE_TOOLCHAIN_FILE="${ANDROID_NDK_HOME}/build/cmake/android.toolchain.cmake"

git clone https://github.com/cake-tech/monero.git ${MONERO_SRC_DIR} --branch ${MONERO_BRANCH}
cd $MONERO_SRC_DIR
git submodule init
git submodule update

for arch in "aarch" "aarch64" "i686" "x86_64"
do
FLAGS=""
PREFIX=${WORKDIR}/prefix_${arch}
DEST_LIB_DIR=${PREFIX}/lib/monero
DEST_INCLUDE_DIR=${PREFIX}/include
export CMAKE_INCLUDE_PATH="${PREFIX}/include"
export CMAKE_LIBRARY_PATH="${PREFIX}/lib"

mkdir -p $DEST_LIB_DIR
mkdir -p $DEST_INCLUDE_DIR

case $arch in
	"aarch"	)
		ANDROID_CLANG=armv7a-linux-androideabi${API}-clang
		ANDROID_CLANGPP=armv7a-linux-androideabi${API}-clang++
		BUILD_64=OFF
		TAG="android-armv7"
		ARCH="armv7-a"
		ARCH_ABI="armeabi-v7a"
		FLAGS="-D CMAKE_ANDROID_ARM_MODE=ON -D NO_AES=true";;
	"aarch64"	)
		ANDROID_CLANG=aarch64-linux-androideabi${API}-clang
		ANDROID_CLANGPP=aarch64-linux-androideabi${API}-clang++
		BUILD_64=ON
		TAG="android-armv8"
		ARCH="armv8-a"
		ARCH_ABI="arm64-v8a";;
	"i686"		)
		ANDROID_CLANG=i686-linux-androideabi${API}-clang
		ANDROID_CLANGPP=i686-linux-androideabi${API}-clang++
		BUILD_64=OFF
		TAG="android-x86"
		ARCH="i686"
		ARCH_ABI="x86";;
	"x86_64"	)  
		ANDROID_CLANG=x86_64-linux-androideabi${API}-clang
		ANDROID_CLANGPP=x86_64-linux-androideabi${API}-clang++
		BUILD_64=ON
		TAG="android-x86_64"
		ARCH="x86-64"
		ARCH_ABI="x86_64";;
esac

cd $MONERO_SRC_DIR
rm -rf ./build/release
mkdir -p ./build/release
cd ./build/release
    cmake \
    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE} \
    -DCMAKE_PREFIX_PATH="${PREFIX}" \
    -DCMAKE_FIND_ROOT_PATH="${PREFIX}" \
    -DCMAKE_BUILD_TYPE=release \
    -DARCH=$ARCH \
    -DANDROID=true \
    -DANDROID_NATIVE_API_LEVEL=$API \
    -DANDROID_ABI=$ARCH_ABI \
    -DANDROID_TOOLCHAIN=clang \
    -DLRELEASE_PATH="${PREFIX}/bin" \
    -DSTATIC=ON \
    -DBUILD_64=$BUILD_64 \
    -DINSTALL_VENDORED_LIBUNBOUND=ON \
    -DUSE_DEVICE_TREZOR=OFF \
    -DBUILD_GUI_DEPS=1 \
    -DBUILD_TESTS=OFF \
    ${FLAGS} ../..
    
make wallet_api -j4
find . -path ./lib -prune -o -name '*.a' -exec cp '{}' lib \;

cp -r ./lib/* $DEST_LIB_DIR
cp ../../src/wallet/api/wallet2_api.h  $DEST_INCLUDE_DIR
done
