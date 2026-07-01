#!/bin/sh

set -e

. ./config.sh

UNBOUND_VERSION=release-1.16.2
UNBOUND_HASH="cbed768b8ff9bfcf11089a5f1699b7e5707f1ea5"
UNBOUND_DIR_PATH="${EXTERNAL_LINUX_SOURCE_DIR}/unbound-1.16.2"

echo "============================ Unbound ============================"
rm -rf ${UNBOUND_DIR_PATH}
git clone https://github.com/NLnetLabs/unbound.git -b ${UNBOUND_VERSION} ${UNBOUND_DIR_PATH}
cd $UNBOUND_DIR_PATH
test `git rev-parse HEAD` = ${UNBOUND_HASH} || exit 1

export CFLAGS=-fPIC
./configure cxxflags=-fPIC cflags=-fPIC \
	--prefix="${EXTERNAL_LINUX_DIR}" \
	--with-ssl="${EXTERNAL_LINUX_DIR}" \
	--with-libexpat="${EXTERNAL_LINUX_DIR}" \
	--enable-static \
	--disable-flto
make
make install
