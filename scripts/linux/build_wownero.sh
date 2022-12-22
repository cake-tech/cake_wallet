#!/bin/sh

. ./config.sh
WOWNERO_VERSION=fix-armv7a-compile
WOWNERO_SRC_DIR=${WORKDIR}/wownero
WOWNERO_SHA_HEAD="373b8842c6075c54cc4904b147f1c86daf7cb60d"

git clone https://git.wownero.com/wownero/wownero.git ${WOWNERO_SRC_DIR} --branch ${WOWNERO_VERSION}
cd $WOWNERO_SRC_DIR
git reset --hard $WOWNERO_SHA_HEAD
git submodule init
git submodule update

for arch in $TYPES_OF_BUILD
do
FLAGS=""
PREFIX=${WORKDIR}/prefix_${arch}
DEST_LIB_DIR=${PREFIX}/lib/wownero
DEST_INCLUDE_DIR=${PREFIX}/include/wownero
export CMAKE_INCLUDE_PATH="${PREFIX}/include"
export CMAKE_LIBRARY_PATH="${PREFIX}/lib"

mkdir -p $DEST_LIB_DIR
mkdir -p $DEST_INCLUDE_DIR

case $arch in
	"x86_64"	)
		BUILD_64=ON
		TAG="linux-x86_64"
		ARCH="x86-64"
		ARCH_ABI="x86_64";;
	"aarch64"	)
		BUILD_64=ON
		TAG="linux-aarch64"
		ARCH="aarch64"
		ARCH_ABI="aarch64";;
esac

cd $WOWNERO_SRC_DIR
rm -rf ./build/release
mkdir -p ./build/release
cd ./build/release
cmake -DCMAKE_CXX_FLAGS="-fPIC" -D USE_DEVICE_TREZOR=OFF -D BUILD_GUI_DEPS=1 -D BUILD_TESTS=OFF -D ARCH=${ARCH} -D STATIC=ON -D BUILD_64=${BUILD_64} -D CMAKE_BUILD_TYPE=release -D INSTALL_VENDORED_LIBUNBOUND=ON -D BUILD_TAG=${TAG} $FLAGS ../..

make wallet_api -j$THREADS
find . -path ./lib -prune -o -name '*.a' -exec cp '{}' lib \;

cp -r ./lib/* $DEST_LIB_DIR
cp ../../src/wallet/api/wallet2_api.h  $DEST_INCLUDE_DIR

CW_DIR="$(pwd)"/../../../../../../../flutter_libmonero
CW_WOWNERO_EXTERNAL_DIR=${CW_DIR}/cw_wownero/ios/External/android	
mkdir -p $CW_WOWNERO_EXTERNAL_DIR/include	
cp ../../src/wallet/api/wallet2_api.h ${CW_WOWNERO_EXTERNAL_DIR}/include
done
