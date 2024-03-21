#!/bin/bash

. ./config.sh
ZMQ_SRC_DIR=$WORKDIR/libzmq
ZMQ_BRANCH=v4.3.3
ZMQ_COMMIT_HASH=04f5bbedee58c538934374dc45182d8fc5926fa3

for arch in "aarch" "aarch64" "i686" "x86_64"
do

PREFIX=$WORKDIR/prefix_${arch}
PATH="${TOOLCHAIN_BASE_DIR}_${arch}/bin:${ORIGINAL_PATH}"

case $arch in
	"aarch"	) TARGET="arm";;
	"i686"		) TARGET="x86";;
	*		) TARGET="${arch}";;
esac 


HOST="${TARGET}-linux-android"
cd $WORKDIR
rm -rf $ZMQ_SRC_DIR
git clone https://github.com/zeromq/libzmq.git ${ZMQ_SRC_DIR} -b ${ZMQ_BRANCH}
cd $ZMQ_SRC_DIR
git checkout ${ZMQ_COMMIT_HASH}
./autogen.sh
CC=clang CXX=clang++ ./configure --prefix=${PREFIX} --host=${HOST} --enable-static --disable-shared
make -j$THREADS
make install

done
