#!/bin/sh

. ./config.sh
ZMQ_SRC_DIR=$WORKDIR/libzmq
ZMQ_BRANCH=v4.3.3
ZMQ_COMMIT_HASH=04f5bbedee58c538934374dc45182d8fc5926fa3

for arch in $TYPES_OF_BUILD
do

PREFIX=$WORKDIR/prefix_${arch}

case $arch in
	"x86_64")  HOST="x86_64-linux-gnu";;
	"aarch64")  HOST="aarch64-linux-gnu";;
	*)	   HOST="x86_64-linux-gnu";;
esac

cd $WORKDIR
rm -rf $ZMQ_SRC_DIR
git clone https://github.com/zeromq/libzmq.git ${ZMQ_SRC_DIR} -b ${ZMQ_BRANCH}
cd $ZMQ_SRC_DIR
git checkout ${ZMQ_COMMIT_HASH}
./autogen.sh
./configure --prefix=${PREFIX} --host=${HOST} --enable-static --disable-shared
make -j$THREADS
make install

done
