#!/bin/sh

. ./config.sh

WOWNERO_URL="https://git.wownero.com/wownero/wownero.git"
WOWNERO_VERSION=v0.11.0.1
WOWNERO_SHA_HEAD="a21819cc22587e16af00e2c3d8f70156c11310a0"
WOWNERO_SRC_DIR=${WORKDIR}/wownero

echo "Cloning wownero from - $WOWNERO_URL to - $WOWNERO_SRC_DIR"		
git clone ${WOWNERO_URL} ${WOWNERO_SRC_DIR} --branch ${WOWNERO_VERSION}
cd $WOWNERO_SRC_DIR
git reset --hard $WOWNERO_SHA_HEAD
git submodule init
git submodule update

for arch in "aarch" "aarch64" "i686" "x86_64"
do
FLAGS=""
PREFIX=${WORKDIR}/prefix_${arch}
DEST_LIB_DIR=${PREFIX}/lib/wownero
DEST_INCLUDE_DIR=${PREFIX}/include/wownero
export CMAKE_INCLUDE_PATH="${PREFIX}/include"
export CMAKE_LIBRARY_PATH="${PREFIX}/lib"
ANDROID_STANDALONE_TOOLCHAIN_PATH="${TOOLCHAIN_BASE_DIR}_${arch}"
PATH="${ANDROID_STANDALONE_TOOLCHAIN_PATH}/bin:${ORIGINAL_PATH}"

mkdir -p $DEST_LIB_DIR
mkdir -p $DEST_INCLUDE_DIR

case $arch in
	"aarch"	)
		CLANG=arm-linux-androideabi-clang
 		CXXLANG=arm-linux-androideabi-clang++
		BUILD_64=OFF
		TAG="android-armv7"
		ARCH="armv7-a"
		ARCH_ABI="armeabi-v7a"
		FLAGS="-D CMAKE_ANDROID_ARM_MODE=ON -D NO_AES=true";;
	"aarch64"	)
		CLANG=aarch64-linux-androideabi-clang
 		CXXLANG=aarch64-linux-androideabi-clang++
		BUILD_64=ON
		TAG="android-armv8"
		ARCH="armv8-a"
		ARCH_ABI="arm64-v8a";;
	"i686"		)
		CLANG=i686-linux-androideabi-clang
 		CXXLANG=i686-linux-androideabi-clang++
		BUILD_64=OFF
		TAG="android-x86"
		ARCH="i686"
		ARCH_ABI="x86";;
	"x86_64"	)  
		CLANG=x86_64-linux-androideabi-clang
 		CXXLANG=x86_64-linux-androideabi-clang++
		BUILD_64=ON
		TAG="android-x86_64"
		ARCH="x86-64"
		ARCH_ABI="x86_64";;
esac

cd $WOWNERO_SRC_DIR
rm -rf ./build/release
mkdir -p ./build/release
cd ./build/release
CC=${CLANG} CXX=${CXXLANG} cmake -DCMAKE_ANDROID_NDK="${ANDROID_NDK_HOME}" -DANDROID_PLATFORM="android-${API}" -DCMAKE_SYSTEM_VERSION="${API}" -D USE_DEVICE_TREZOR=OFF -D BUILD_GUI_DEPS=1 -D BUILD_TESTS=OFF -D ARCH=${ARCH} -D STATIC=ON -D BUILD_64=${BUILD_64} -D CMAKE_BUILD_TYPE=release -D ANDROID=true -D INSTALL_VENDORED_LIBUNBOUND=ON -D BUILD_TAG=${TAG} -D CMAKE_SYSTEM_NAME="Android" -D CMAKE_ANDROID_STANDALONE_TOOLCHAIN="${ANDROID_STANDALONE_TOOLCHAIN_PATH}" -D CMAKE_ANDROID_ARCH_ABI=${ARCH_ABI} $FLAGS ../..

make wallet_api -j$THREADS
find . -path ./lib -prune -o -name '*.a' -exec cp '{}' lib \;

cp -r ./lib/* $DEST_LIB_DIR
cp ../../src/wallet/api/wallet2_api.h  $DEST_INCLUDE_DIR
done
