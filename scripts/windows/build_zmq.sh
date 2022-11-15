#!/bin/sh

. ./config.sh
ZMQ_SRC_DIR=$WORKDIR/libzmq
ZMQ_BRANCH=v4.3.3
ZMQ_COMMIT_HASH=04f5bbedee58c538934374dc45182d8fc5926fa3

cd $WORKDIR
rm -rf $ZMQ_SRC_DIR
git clone https://github.com/zeromq/libzmq.git ${ZMQ_SRC_DIR} -b ${ZMQ_BRANCH}
cd $ZMQ_SRC_DIR
git checkout ${ZMQ_COMMIT_HASH}
./autogen.sh
#CC=x86_64-w64-mingw32-gcc
#CXX=x86_64-w64-mingw32-g++
#HOST=x86_64-w64-mingw32
HOST="x86_64-windows-gnu"  # TODO see why we cannot use the same HOST as with the other libraries
#CROSS_COMPILE="x86_64-w64-mingw32.static-"
#CXXFLAGS=-std=c++11
./configure \
	--without-documentation \
	--disable-shared \
	--without-libsodium \
	--disable-curve \
	--prefix=${PREFIX} \
	--host=${HOST} \
	--enable-static #\
	#CFLAGS="-Wall -Wno-pedantic-ms-format -DLIBCZMQ_EXPORTS -DZMQ_DEFINED_STDINT -lzmq -lws2_32 -liphlpapi -lrpcrt4"
make -j$THREADS
make install

# See http://vrecan.github.io/post/crosscompile_go_zeromq/
# See https://stackoverflow.com/questions/21322707/zlib-header-not-found-when-cross-compiling-with-mingw
