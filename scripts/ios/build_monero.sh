#!/bin/sh

. ./config.sh

MONERO_URL="https://github.com/cake-tech/monero.git"
MONERO_DIR_PATH="${EXTERNAL_IOS_SOURCE_DIR}/monero"
MONERO_VERSION=release-v0.18.2.2
BUILD_TYPE=release
PREFIX=${EXTERNAL_IOS_DIR}
DEST_LIB_DIR=${EXTERNAL_IOS_LIB_DIR}/monero
DEST_INCLUDE_DIR=${EXTERNAL_IOS_INCLUDE_DIR}/monero

echo "Cloning monero from - $MONERO_URL to - $MONERO_DIR_PATH"		
git clone $MONERO_URL $MONERO_DIR_PATH
cd $MONERO_DIR_PATH
git checkout $MONERO_VERSION
git submodule update --init --force
mkdir -p build
cd ..

mkdir -p $DEST_LIB_DIR
mkdir -p $DEST_INCLUDE_DIR

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ -z $INSTALL_PREFIX ]; then
    INSTALL_PREFIX=${ROOT_DIR}/monero
fi

for arch in "arm64" #"armv7" "arm64"
do

echo "Building IOS ${arch}"
export CMAKE_INCLUDE_PATH="${PREFIX}/include"
export CMAKE_LIBRARY_PATH="${PREFIX}/lib"

case $arch in
	"armv7"	)
		DEST_LIB=../../lib-armv7;;
	"arm64"	)
		DEST_LIB=../../lib-armv8-a;;
esac

rm -r monero/build > /dev/null

mkdir -p monero/build/${BUILD_TYPE}
pushd monero/build/${BUILD_TYPE}
cmake -D IOS=ON \
	-DARCH=${arch} \
	-DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
	-DSTATIC=ON \
	-DBUILD_GUI_DEPS=ON \
	-DUNBOUND_INCLUDE_DIR=${EXTERNAL_IOS_INCLUDE_DIR} \
	-DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX}  \
    -DUSE_DEVICE_TREZOR=OFF \
	../..
make wallet_api -j4
find . -path ./lib -prune -o -name '*.a' -exec cp '{}' lib \;
cp -r ./lib/* $DEST_LIB_DIR
cp ../../src/wallet/api/wallet2_api.h  $DEST_INCLUDE_DIR
popd

done
