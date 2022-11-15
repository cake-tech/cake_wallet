#!/bin/sh

. ./config.sh

ZLIB_DIR=$WORKDIR/zlib
ZLIB_TAG=v1.2.11
ZLIB_COMMIT_HASH="cacf7f1d4e3d44d871b605da3b647f07d718623f"

if [ ! -d "$ZLIB_DIR" ] ; then
	git clone -b $ZLIB_TAG --depth 1 https://github.com/madler/zlib $ZLIB_DIR
fi
cd $ZLIB_DIR
git reset --hard $ZLIB_COMMIT_HASH

CC=x86_64-w64-mingw32-gcc
CXX=x86_64-w64-mingw32-g++
HOST=x86_64-w64-mingw32
CROSS_COMPILE="x86_64-w64-mingw32.static-"
./configure \
	--static \
	--prefix=${PREFIX}
make
make install

# See https://stackoverflow.com/questions/21322707/zlib-header-not-found-when-cross-compiling-with-mingw
