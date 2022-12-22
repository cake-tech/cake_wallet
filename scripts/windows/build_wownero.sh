#!/bin/bash

. ./config.sh
: '
WOWNERO_VERSION=fix-armv7a-compile
WOWNERO_SHA_HEAD="373b8842c6075c54cc4904b147f1c86daf7cb60d"

WOWNERO_VERSION=dev
WOWNERO_SHA_HEAD="fc907a957078cae2dc68348886a33363848dd089"
'
WOWNERO_VERSION=fix-armv7a-compile
WOWNERO_SHA_HEAD="373b8842c6075c54cc4904b147f1c86daf7cb60d"

WOWNERO_SRC_DIR=${WORKDIR}/wownero

if [[ ! -d $WOWNERO_SRC_DIR ]]; then
	git clone https://git.wownero.com/wownero/wownero.git ${WOWNERO_SRC_DIR} --branch ${WOWNERO_VERSION}
fi
cd $WOWNERO_SRC_DIR
git reset --hard $WOWNERO_SHA_HEAD
git submodule init
git submodule update

FLAGS=""
DEST_LIB_DIR=${PREFIX}/lib/wownero
DEST_INCLUDE_DIR=${PREFIX}/include/wownero
export CMAKE_INCLUDE_PATH="${PREFIX}/include"
export CMAKE_LIBRARY_PATH="${PREFIX}/lib"

mkdir -p $DEST_LIB_DIR
mkdir -p $DEST_INCLUDE_DIR
LIBUNBOUND_PATH=${PREFIX}/lib/libunbound.a
if [ -f "$LIBUNBOUND_PATH" ]; then
  cp $LIBUNBOUND_PATH $DEST_LIB_DIR
fi

BUILD_64=ON
TAG="win-x86_64"
ARCH="x86-64"
ARCH_ABI="x86_64"

cd $WOWNERO_SRC_DIR

# Patch to include <limits> to avoid issues with GCC11 as in https://github.com/MultiMC/Launcher/issues/3574
printf '%s\n%s\n' "#include <limits>" "$(cat ${WORKDIR}/wownero/contrib/epee/src/wipeable_string.cpp)" > ${WORKDIR}/wownero/contrib/epee/src/wipeable_string.cpp
printf '%s\n%s\n' "#include <limits>" "$(cat ${WORKDIR}/wownero/contrib/epee/src/buffer.cpp)" > ${WORKDIR}/wownero/contrib/epee/src/buffer.cpp
printf '%s\n%s\n' "#include <limits>" "$(cat ${WORKDIR}/wownero/src/wallet/wallet_rpc_helpers.h)" > ${WORKDIR}/wownero/src/wallet/wallet_rpc_helpers.h

rm -rf ./build/release
mkdir -p ./build/release
cd ./build/release

CC=x86_64-w64-mingw32.static-gcc
CXX=x86_64-w64-mingw32.static-g++
HOST=x86_64-w64-mingw32.static
CROSS_COMPILE="x86_64-w64-mingw32.static-"
x86_64-w64-mingw32.static-cmake \
	-DCMAKE_FIND_ROOT_PATH="${PREFIX};${PREFIX}/include;${PREFIX}/lib" \
	-DCMAKE_CXX_FLAGS="-fPIC" \
	-D USE_DEVICE_TREZOR=OFF \
	-D BUILD_GUI_DEPS=1 \
	-D BUILD_TESTS=OFF \
	-D ARCH=${ARCH} \
	-D STATIC=ON \
	-D BUILD_64=${BUILD_64} \
	-D CMAKE_BUILD_TYPE=release \
	-D INSTALL_VENDORED_LIBUNBOUND=ON \
	-D BUILD_TAG=${TAG} $FLAGS ../..

make wallet_api -j$THREADS
find . -path ./lib -prune -o -name '*.a' -exec cp '{}' lib \;

cp -r ./lib/* $DEST_LIB_DIR
cp ../../src/wallet/api/wallet2_api.h  $DEST_INCLUDE_DIR

CW_DIR="$(pwd)"/../../../../../../../flutter_libmonero # 🧐
CW_WOWNERO_EXTERNAL_DIR=${CW_DIR}/cw_wownero/ios/External/android
mkdir -p $CW_WOWNERO_EXTERNAL_DIR/include
cp ../../src/wallet/api/wallet2_api.h ${CW_WOWNERO_EXTERNAL_DIR}/include
