#!/bin/sh

. ./config.sh

WOWNERO_URL="https://git.wownero.com/wownero/wownero.git"
WOWNERO_DIR_PATH="${EXTERNAL_IOS_SOURCE_DIR}/wownero"
WOWNERO_VERSION=v0.11.1.0
WOWNERO_SHA_HEAD="1b8475003c065b0387f21323dad8a03b131ae7d1"

BUILD_TYPE=release
PREFIX=${EXTERNAL_IOS_DIR}
DEST_LIB_DIR=${EXTERNAL_IOS_LIB_DIR}/wownero
DEST_INCLUDE_DIR=${EXTERNAL_IOS_INCLUDE_DIR}/wownero

echo "Cloning wownero from - $WOWNERO_URL to - $WOWNERO_DIR_PATH"		
git clone $WOWNERO_URL $WOWNERO_DIR_PATH
cd $WOWNERO_DIR_PATH
git reset --hard $WOWNERO_SHA_HEAD
git checkout $WOWNERO_VERSION
git submodule update --init --force
mkdir -p build
cd ..

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ -z $INSTALL_PREFIX ]; then
    INSTALL_PREFIX=${ROOT_DIR}/wownero
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

rm -rf wownero/build > /dev/null

mkdir -p wownero/build/${BUILD_TYPE}
pushd wownero/build/${BUILD_TYPE}
cmake -D IOS=ON \
	-DARCH=${arch} \
	-DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
	-DSTATIC=ON \
	-DBUILD_GUI_DEPS=ON \
	-DINSTALL_VENDORED_LIBUNBOUND=ON \
	-DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX}  \
    -DUSE_DEVICE_TREZOR=OFF \
    -DMANUAL_SUBMODULES=1 \
	../..
make -j4 && make install
cp src/cryptonote_basic/libcryptonote_basic.a ${DEST_LIB}
cp src/offshore/liboffshore.a ${DEST_LIB}
popd

done

#only for arm64
mkdir -p $DEST_LIB_DIR
mkdir -p $DEST_INCLUDE_DIR
cp ${WOWNERO_DIR_PATH}/lib-armv8-a/* $DEST_LIB_DIR
cp ${WOWNERO_DIR_PATH}/include/wallet/api/* $DEST_INCLUDE_DIR