#!/bin/sh

. ./config.sh

SALVIUM_URL="https://github.com/salvium/salvium.git"
SALVIUM_DIR_PATH="${EXTERNAL_MACOS_SOURCE_DIR}/salvium"
SALVIUM_VERSION=tags/v0.6.4
BUILD_TYPE=release
PREFIX=${EXTERNAL_MACOS_DIR}
DEST_LIB_DIR=${EXTERNAL_MACOS_LIB_DIR}/salvium
DEST_INCLUDE_DIR=${EXTERNAL_MACOS_INCLUDE_DIR}/salvium
ARCH=`uname -m`

echo "Cloning salvium from - $SALVIUM_URL to - $SALVIUM_DIR_PATH"		
git clone $SALVIUM_URL $SALVIUM_DIR_PATH
cd $SALVIUM_DIR_PATH
git checkout $SALVIUM_VERSION
git submodule update --init --force
mkdir -p build
cd ..

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ -z $INSTALL_PREFIX ]; then
    INSTALL_PREFIX=${ROOT_DIR}/salvium
fi

mkdir -p $DEST_LIB_DIR
mkdir -p $DEST_INCLUDE_DIR

echo "Building MACOS ${ARCH}"
export CMAKE_INCLUDE_PATH="${PREFIX}/include"
export CMAKE_LIBRARY_PATH="${PREFIX}/lib"
rm -rf salvium/build > /dev/null

mkdir -p salvium/build/${BUILD_TYPE}
pushd salvium/build/${BUILD_TYPE}
cmake -DARCH=${ARCH} \
	-DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
	-DSTATIC=ON \
	-DBUILD_GUI_DEPS=ON \
	-DINSTALL_VENDORED_LIBUNBOUND=ON \
	-DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX}  \
    -DUSE_DEVICE_TREZOR=OFF \
	../..
make -j4 && make install
find . -path ./lib -prune -o -name '*.a' -exec cp '{}' lib \;
cp -r ./lib/* $DEST_LIB_DIR
cp ../../src/wallet/api/wallet2_api.h  $DEST_INCLUDE_DIR
popd

