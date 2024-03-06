#!/bin/sh

. ./config.sh

LIBWALLET_PATH="${EXTERNAL_MACOS_SOURCE_DIR}/libwallet"
LIBWALLET_URL="https://github.com/itswisdomagain/libwallet.git"
LIBWALLET_COMMIT_HASH=e1b9f6043359d191cfd2fbfaa345396a009d0946

echo "======================= DECRED LIBWALLET ========================="

echo "Cloning DECRED LIBWALLET from - $LIBWALLET_URL"
if [ -e $LIBWALLET_PATH ]; then
       rm -fr $LIBWALLET_PATH
fi
mkdir -p $LIBWALLET_PATH
git clone $LIBWALLET_URL $LIBWALLET_PATH --branch cgo
cd $LIBWALLET_PATH
git checkout ${LIBWALLET_COMMIT_HASH}

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