#!/bin/sh

. ./config.sh

OPEN_SSL_URL="https://github.com/x2on/OpenSSL-for-iPhone.git"
OPEN_SSL_DIR_PATH="${EXTERNAL_IOS_SOURCE_DIR}/OpenSSL"

echo "============================ OpenSSL ============================"

echo "Cloning Open SSL from - $OPEN_SSL_URL"
git clone $OPEN_SSL_URL $OPEN_SSL_DIR_PATH
cd $OPEN_SSL_DIR_PATH
sed -i '' "s/IOS_MIN_SDK_VERSION=\"12.0\"/IOS_MIN_SDK_VERSION=\"10.0\"/g" build-libssl.sh

./build-libssl.sh --version=1.1.1k --archs="x86_64 arm64 armv7s armv7" --targets="ios64-cross-arm64 ios-cross-armv7 ios-cross-armv7s" --deprecated

mv ${OPEN_SSL_DIR_PATH}/include/* $EXTERNAL_IOS_INCLUDE_DIR
mv ${OPEN_SSL_DIR_PATH}/lib/* $EXTERNAL_IOS_LIB_DIR