#!/bin/sh

. ./config.sh

SODIUM_PATH="${EXTERNAL_IOS_SOURCE_DIR}/libsodium"
SODIUM_URL="https://github.com/jedisct1/libsodium.git"

echo "============================ SODIUM ============================"

echo "Cloning SODIUM from - $SODIUM_URL"
git clone $SODIUM_URL $SODIUM_PATH --branch stable
git checkout 675149b9b8b66ff44152553fb3ebf9858128363d
cd $SODIUM_PATH
./autogen.sh
./dist-build/ios.sh

mv ${SODIUM_PATH}/libsodium-ios/include/* $EXTERNAL_IOS_INCLUDE_DIR
mv ${SODIUM_PATH}/libsodium-ios/lib/* $EXTERNAL_IOS_LIB_DIR