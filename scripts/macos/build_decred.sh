#!/bin/sh

. ./config.sh

LIBWALLET_PATH="${EXTERNAL_MACOS_SOURCE_DIR}/libwallet"
LIBWALLET_URL="https://github.com/itswisdomagain/libwallet.git"

echo "======================= DECRED LIBWALLET ========================="

echo "Cloning DECRED LIBWALLET from - $LIBWALLET_URL"
git clone $LIBWALLET_URL $LIBWALLET_PATH --branch cgo
cd $LIBWALLET_PATH
rm -rf ./build
go build -buildmode=c-archive -o ./build/libdcrwallet.a ./cgo

CW_DECRED_DIR=${CW_ROOT}/cw_decred
HEADER_DIR=$CW_DECRED_DIR/lib/api
mv ${LIBWALLET_PATH}/build/libdcrwallet.h $HEADER_DIR

DEST_LIB_DIR=${CW_DECRED_DIR}/macos/External/lib
mkdir -p $DEST_LIB_DIR
mv ${LIBWALLET_PATH}/build/libdcrwallet.a $DEST_LIB_DIR

cd $CW_DECRED_DIR
dart run ffigen