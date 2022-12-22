#!/bin/bash

. ./config.sh

ZMQ_SRC_DIR=$WORKDIR/libzmq
: '
ZMQ_BRANCH=v4.3.4
ZMQ_COMMIT_HASH=4097855ddaaa65ed7b5e8cb86d143842a594eebd

ZMQ_BRANCH=v4.3.3
ZMQ_COMMIT_HASH=04f5bbedee58c538934374dc45182d8fc5926fa3

ZMQ_BRANCH=v4.3.1
ZMQ_COMMIT_HASH=2cb1240db64ce1ea299e00474c646a2453a8435b
'
ZMQ_BRANCH=v4.3.1
ZMQ_COMMIT_HASH=2cb1240db64ce1ea299e00474c646a2453a8435b

cd $WORKDIR
if [[ ! -d $ZMQ_SRC_DIR ]]; then
	git clone https://github.com/zeromq/libzmq.git ${ZMQ_SRC_DIR} --branch ${ZMQ_BRANCH}
fi
cd $ZMQ_SRC_DIR
git reset --hard ${ZMQ_COMMIT_HASH}

./autogen.sh
CC=x86_64-w64-mingw32.static-gcc
CXX=x86_64-w64-mingw32.static-g++
HOST=x86_64-w64-mingw32.static
CROSS_COMPILE="x86_64-w64-mingw32.static-"
./configure \
	--without-docs \
	--without-docs \
	--disable-shared \
	--disable-curve \
	--prefix=${PREFIX} \
	--host=${HOST} \
	--enable-static \
	--with-pic #\
	#CFLAGS="-Wall -Wno-pedantic-ms-format -DLIBCZMQ_EXPORTS -DZMQ_DEFINED_STDINT"
make -j$THREADS
make install

# See http://vrecan.github.io/post/crosscompile_go_zeromq/
# See https://stackoverflow.com/questions/21322707/zlib-header-not-found-when-cross-compiling-with-mingw
