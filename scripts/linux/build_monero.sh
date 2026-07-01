#!/bin/sh

. ./config.sh

MONERO_URL="https://github.com/cake-tech/monero.git"
MONERO_DIR_PATH="${EXTERNAL_LINUX_SOURCE_DIR}/monero"
MONERO_VERSION=release-v0.18.3.2
PREFIX=${EXTERNAL_LINUX_DIR}
DEST_LIB_DIR=${EXTERNAL_LINUX_LIB_DIR}/monero
DEST_INCLUDE_DIR=${EXTERNAL_LINUX_INCLUDE_DIR}/monero

echo "Cloning monero from - $MONERO_URL to - $MONERO_DIR_PATH"
git clone $MONERO_URL $MONERO_DIR_PATH
cd $MONERO_DIR_PATH
git checkout $MONERO_VERSION
git submodule update --init --force
rm -rf ./build/release
mkdir -p ./build/release
cd ./build/release

mkdir -p $DEST_LIB_DIR
mkdir -p $DEST_INCLUDE_DIR

echo "Building LINUX"
export CMAKE_INCLUDE_PATH="${PREFIX}/include"
export CMAKE_LIBRARY_PATH="${PREFIX}/lib"

cmake -DSTATIC=ON \
	-DBUILD_GUI_DEPS=ON \
	-DUNBOUND_INCLUDE_DIR=${EXTERNAL_LINUX_INCLUDE_DIR} \
	-DCMAKE_INSTALL_PREFIX=${PREFIX} \
	  -DUSE_DEVICE_TREZOR=OFF \
    -DMANUAL_SUBMODULES=1 \
	../..

make wallet_api -j$(($(nproc) / 2))

find . -path ./lib -prune -o -name '*.a' -exec cp '{}' lib \;
cp -r ./lib/* $DEST_LIB_DIR
cp ../../src/wallet/api/wallet2_api.h $DEST_INCLUDE_DIR
