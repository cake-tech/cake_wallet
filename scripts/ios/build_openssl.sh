#!/bin/sh

. ./config.sh

OPEN_SSL_URL="https://github.com/x2on/OpenSSL-for-iPhone.git"
OPEN_SSL_DIR_PATH="${EXTERNAL_IOS_SOURCE_DIR}/OpenSSL"

echo "============================ OpenSSL ============================"

echo "Cloning Open SSL from - $OPEN_SSL_URL"
git clone $OPEN_SSL_URL $OPEN_SSL_DIR_PATH
cd $OPEN_SSL_DIR_PATH
./build-libssl.sh --version=1.1.1q --targets="ios-cross-arm64" --deprecated

mv ${OPEN_SSL_DIR_PATH}/include/* $EXTERNAL_IOS_INCLUDE_DIR
mv ${OPEN_SSL_DIR_PATH}/lib/libcrypto-iOS.a ${EXTERNAL_IOS_LIB_DIR}/libcrypto.a
mv ${OPEN_SSL_DIR_PATH}/lib/libssl-iOS.a ${EXTERNAL_IOS_LIB_DIR}/libssl.a