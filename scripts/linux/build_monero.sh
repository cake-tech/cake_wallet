#!/bin/sh

. ./config.sh
MONERO_BRANCH=v0.17.3.0-android
MONERO_SRC_DIR=${WORKDIR}/monero

git clone https://github.com/cake-tech/monero.git ${MONERO_SRC_DIR} --branch ${MONERO_BRANCH}
cd $MONERO_SRC_DIR
git submodule init
git submodule update

for arch in "x86_64"
do
FLAGS=""
PREFIX=${WORKDIR}/prefix_${arch}
DEST_LIB_DIR=${PREFIX}/lib/monero
DEST_INCLUDE_DIR=${PREFIX}/include/monero
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
esac

cd $MONERO_SRC_DIR
rm -rf ./build/release
mkdir -p ./build/release
cd ./build/release
cmake -DCMAKE_CXX_FLAGS="-fPIC" -D USE_DEVICE_TREZOR=OFF -D BUILD_GUI_DEPS=1 -D BUILD_TESTS=OFF -D ARCH=${ARCH} -D BUILD_64=${BUILD_64} -D CMAKE_BUILD_TYPE=release -D INSTALL_VENDORED_LIBUNBOUND=ON -D BUILD_TAG=${TAG} $FLAGS ../..
    
make wallet_api -j$THREADS
find . -path ./lib -prune -o -name '*.a' -exec cp '{}' lib \;

cp -r ./lib/* $DEST_LIB_DIR
cp ../../src/wallet/api/wallet2_api.h  $DEST_INCLUDE_DIR
done
