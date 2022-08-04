#!/bin/sh

. ./config.sh

UNBOUND_VERSION=1.13.2
UNBOUND_HASH=0a13b547f3b92a026b5ebd0423f54c991e5718037fd9f72445817f6a040e1a83
UNBOUND_URL="https://www.nlnetlabs.nl/downloads/unbound/unbound-${UNBOUND_VERSION}.tar.gz"
UNBOUND_DIR_PATH="${EXTERNAL_IOS_SOURCE_DIR}/unbound-${UNBOUND_VERSION}"
UNBOUND_ARCH_PATH=${EXTERNAL_IOS_SOURCE_DIR}/unbound-${UNBOUND_VERSION}.tar.gz

echo $UNBOUND_DIR_PATH
echo "============================ Unbound ============================"
curl $UNBOUND_URL -L -o $UNBOUND_ARCH_PATH
tar -xzf $UNBOUND_ARCH_PATH -C $EXTERNAL_IOS_SOURCE_DIR
cd $UNBOUND_DIR_PATH

export IOS_SDK=iPhone
export IOS_CPU=arm64
export IOS_PREFIX=$EXTERNAL_IOS_DIR
export AUTOTOOLS_HOST=aarch64-apple-ios
export AUTOTOOLS_BUILD="$(./config.guess)"
source ./contrib/ios/setenv_ios.sh
./contrib/ios/install_tools.sh
./contrib/ios/install_expat.sh
./configure --build="$AUTOTOOLS_BUILD" --host="$AUTOTOOLS_HOST" --prefix="$IOS_PREFIX" --with-ssl="$IOS_PREFIX" --disable-gost --with-libexpat="$IOS_PREFIX"
make
make install