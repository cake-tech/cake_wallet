#!/bin/sh

. ./config.sh

LIBWALLET_PATH="${EXTERNAL_MACOS_SOURCE_DIR}/libwallet"
LIBWALLET_URL="https://github.com/decred/libwallet.git"
LIBWALLET_VERSION="87b2769538db3065b334d247b25774593fc6443d"

echo "======================= DECRED LIBWALLET ========================="

echo "Cloning DECRED LIBWALLET from - $LIBWALLET_URL"
if [ -e $LIBWALLET_PATH ]; then
       rm -fr $LIBWALLET_PATH
fi
mkdir -p $LIBWALLET_PATH
git clone $LIBWALLET_URL $LIBWALLET_PATH
cd $LIBWALLET_PATH
git checkout $LIBWALLET_VERSION

if [ -e ./build ]; then
       rm -fr ./build
fi
go build -buildmode=c-archive -o ./build/libdcrwallet.a ./cgo

CW_DECRED_DIR=${CW_ROOT}/cw_decred
HEADER_DIR=$CW_DECRED_DIR/lib/api
mv ${LIBWALLET_PATH}/build/libdcrwallet.h $HEADER_DIR

DEST_LIB_DIR=${CW_DECRED_DIR}/macos/External/lib
mkdir -p $DEST_LIB_DIR
mv ${LIBWALLET_PATH}/build/libdcrwallet.a $DEST_LIB_DIR

cd $CW_DECRED_DIR
dart run ffigen
