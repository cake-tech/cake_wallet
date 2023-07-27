#!/bin/sh

. ./config.sh

HAVEN_URL="https://github.com/haven-protocol-org/haven-main.git"
HAVEN_DIR_PATH="${EXTERNAL_IOS_SOURCE_DIR}/haven"
HAVEN_VERSION=tags/v3.0.7
BUILD_TYPE=release
PREFIX=${EXTERNAL_IOS_DIR}
DEST_LIB_DIR=${EXTERNAL_IOS_LIB_DIR}/haven
DEST_INCLUDE_DIR=${EXTERNAL_IOS_INCLUDE_DIR}/haven

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

rm -rf haven/build > /dev/null

mkdir -p haven/build/${BUILD_TYPE}
pushd haven/build/${BUILD_TYPE}
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
cp ${HAVEN_DIR_PATH}/lib-armv8-a/* $DEST_LIB_DIR
cp ${HAVEN_DIR_PATH}/include/wallet/api/* $DEST_INCLUDE_DIR