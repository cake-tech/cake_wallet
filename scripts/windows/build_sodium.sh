#!/bin/bash

. ./config.sh
SODIUM_SRC_DIR=${WORKDIR}/libsodium
SODIUM_BRANCH=1.0.18 # See https://users.rust-lang.org/t/cross-compilation-linux-windows-pthread-linking-issues/50824/5 and https://github.com/jedisct1/libsodium/issues/962

cd $WORKDIR
rm -rf $SODIUM_SRC_DIR
git clone https://github.com/jedisct1/libsodium.git $SODIUM_SRC_DIR -b $SODIUM_BRANCH
cd $SODIUM_SRC_DIR

./autogen.sh
CC=x86_64-w64-mingw32.static-gcc
CXX=x86_64-w64-mingw32.static-g++
HOST=x86_64-w64-mingw32.static
#CFLAGS='-Os'
./configure \
	--prefix=${PREFIX} \
	--host=${HOST} \
	--enable-static \
	--disable-shared
make -j$THREADS
make install
