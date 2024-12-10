#!/bin/sh

. ./config.sh

SALVIUM_URL="https://github.com/salvium/salvium.git"
SALVIUM_DIR_PATH="${EXTERNAL_IOS_SOURCE_DIR}/salvium"
SALVIUM_VERSION=tags/v0.6.4
BUILD_TYPE=release
PREFIX=${EXTERNAL_IOS_DIR}
DEST_LIB_DIR=${EXTERNAL_IOS_LIB_DIR}/salvium
DEST_INCLUDE_DIR=${EXTERNAL_IOS_INCLUDE_DIR}/salvium

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

rm -rf salvium/build > /dev/null

mkdir -p salvium/build/${BUILD_TYPE}
pushd salvium/build/${BUILD_TYPE}
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
cp src/cryptonote_basic/libcryptonote_basic.a ${DEST_LIB}
cp src/offshore/liboffshore.a ${DEST_LIB}
popd

done

#only for arm64
mkdir -p $DEST_LIB_DIR
mkdir -p $DEST_INCLUDE_DIR
cp ${SALVIUM_DIR_PATH}/lib-armv8-a/* $DEST_LIB_DIR
cp ${SALVIUM_DIR_PATH}/include/wallet/api/* $DEST_INCLUDE_DIR
