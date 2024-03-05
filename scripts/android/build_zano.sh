#!/bin/sh
set -o xtrace

. ./config.sh
#HAVEN_VERSION=tags/v3.0.7
ZANO_SRC_DIR=${WORKDIR}/zano
ZANO_CHECKOUT_ID=master

#git clone --recursive https://github.com/hyle-team/zano.git ${ZANO_SRC_DIR}
cd $ZANO_SRC_DIR
#git checkout ${ZANO_CHECKOUT_ID}
#git submodule init
#git submodule update
#git pull -r
#if [ $? -ne 0 ]; then
#    echo "Failed to git pull -r"
#    exit 1
#fi

for arch in "aarch" "aarch64" "i686" "x86_64"
do
FLAGS=""
PREFIX=${WORKDIR}/prefix_${arch}
DEST_LIB_DIR=${PREFIX}/lib/zano
DEST_INCLUDE_DIR=${PREFIX}/include/zano
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

cd $ZANO_SRC_DIR
 rm -rf ./build/release
mkdir -p ./build/release
cd ./build/release
CC=${CLANG} CXX=${CXXLANG} cmake -S../.. -DCMAKE_INSTALL_PREFIX=./_install -D CAKEWALLET=TRUE -D TESTNET=TRUE  -D USE_DEVICE_TREZOR=OFF -D BUILD_GUI_DEPS=1 -D BUILD_TESTS=OFF -D ARCH=${ARCH} -D STATIC=ON -D BUILD_64=${BUILD_64} -D CMAKE_BUILD_TYPE=release -D ANDROID=true -D INSTALL_VENDORED_LIBUNBOUND=ON -D BUILD_TAG=${TAG} -D CMAKE_SYSTEM_NAME="Android" -D CMAKE_ANDROID_STANDALONE_TOOLCHAIN="${ANDROID_STANDALONE_TOOLCHAIN_PATH}" -D CMAKE_ANDROID_ARCH_ABI=${ARCH_ABI} $FLAGS
if [ $? -ne 0 ]; then
    echo "Failed to perform cmake"
    exit 1
fi



# make wallet_api -j$THREADS
# find . -path ./lib -prune -o -name '*.a' -exec cp '{}' lib \;
#cd ../..
#pwd

cmake  --build . --config Release --verbose --target install -- -j 4
if [ $? -ne 0 ]; then
    echo "Failed to perform cmake install"
    exit 1
fi
#exit 1

cp -r ./_install/$ARCH_ABI/lib/* $DEST_LIB_DIR
#cp ../../src/wallet/api/wallet2_api.h  $DEST_INCLUDE_DIR

done
