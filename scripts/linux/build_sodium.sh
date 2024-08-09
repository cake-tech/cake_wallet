#!/bin/sh

set -e

. ./config.sh

SODIUM_PATH="${EXTERNAL_LINUX_SOURCE_DIR}/libsodium"
SODIUM_URL="https://github.com/jedisct1/libsodium.git"

echo "============================ SODIUM ============================"

echo "Cloning SODIUM from - $SODIUM_URL"
git clone $SODIUM_URL $SODIUM_PATH --branch stable
cd $SODIUM_PATH


./configure --prefix=${EXTERNAL_LINUX_DIR}
make
make install
