#!/bin/sh

. ./config.sh

HAVEN_URL="https://github.com/haven-protocol-org/haven-main.git"
HAVEN_DIR_PATH="${EXTERNAL_MACOS_SOURCE_DIR}/haven"
HAVEN_VERSION=tags/v3.0.0
BUILD_TYPE=release
PREFIX=${EXTERNAL_MACOS_DIR}
DEST_LIB_DIR=${EXTERNAL_MACOS_LIB_DIR}/haven
DEST_INCLUDE_DIR=${EXTERNAL_MACOS_INCLUDE_DIR}/haven
ARCH=`uname -m`

echo "Cloning haven from - $HAVEN_URL to - $HAVEN_DIR_PATH"		
git clone $HAVEN_URL $HAVEN_DIR_PATH
cd $HAVEN_DIR_PATH
git checkout $HAVEN_VERSION
git submodule update --init --force
mkdir -p build
cd ..

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ -z $INSTALL_PREFIX ]; then
    INSTALL_PREFIX=${ROOT_DIR}/haven
fi

mkdir -p $DEST_LIB_DIR
mkdir -p $DEST_INCLUDE_DIR

echo "Building MACOS ${ARCH}"
export CMAKE_INCLUDE_PATH="${PREFIX}/include"
export CMAKE_LIBRARY_PATH="${PREFIX}/lib"
rm -rf haven/build > /dev/null

mkdir -p haven/build/${BUILD_TYPE}
pushd haven/build/${BUILD_TYPE}
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

