#!/bin/sh

. ./config.sh
SODIUM_SRC_DIR=${WORKDIR}/libsodium
SODIUM_BRANCH=1.0.16

cd $WORKDIR
rm -rf $SODIUM_SRC_DIR
git clone https://github.com/jedisct1/libsodium.git $SODIUM_SRC_DIR -b $SODIUM_BRANCH
cd $SODIUM_SRC_DIR
./autogen.sh
CC=x86_64-w64-mingw32-gcc
CXX=x86_64-w64-mingw32-g++
HOST=x86_64-w64-mingw32
CROSS_COMPILE="x86_64-w64-mingw32.static-"
./configure \
	--prefix=${PREFIX} \
	--host=${HOST} \
	--enable-static \
	--disable-shared
make -j$THREADS
make install
