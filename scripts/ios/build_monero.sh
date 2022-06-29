#!/bin/sh

. ./config.sh

MONERO_URL="https://github.com/cake-tech/monero.git"
MONERO_DIR_PATH="${EXTERNAL_IOS_SOURCE_DIR}/monero"
MONERO_VERSION=release-v0.17.3.2
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
	-DINSTALL_VENDORED_LIBUNBOUND=ON \
	-DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX}  \
    -DUSE_DEVICE_TREZOR=OFF \
	../..
make -j4 && make install
cp external/randomx/librandomx.a ${DEST_LIB}/
cp src/cryptonote_basic/libcryptonote_basic.a ${DEST_LIB}/
cp src/cryptonote_basic/libcryptonote_format_utils_basic.a ${DEST_LIB}/
popd

done

#only for arm64
mkdir -p $DEST_LIB_DIR
mkdir -p $DEST_INCLUDE_DIR
cp ${MONERO_DIR_PATH}/lib-armv8-a/* $DEST_LIB_DIR
cp ${MONERO_DIR_PATH}/include/wallet/api/* $DEST_INCLUDE_DIR
