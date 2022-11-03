#!/bin/sh

. ./config.sh
SODIUM_SRC_DIR=${WORKDIR}/libsodium
SODIUM_BRANCH=1.0.16

for arch in $TYPES_OF_BUILD
do

PREFIX=${WORKDIR}/prefix_${arch}

case $arch in
	"x86_64")  HOST="x86_64-linux-gnu";;
	"aarch64")  HOST="aarch64-linux-gnu";;
	*)	   HOST="x86_64-linux-gnu";;
esac

cd $WORKDIR
rm -rf $SODIUM_SRC_DIR
git clone https://github.com/jedisct1/libsodium.git $SODIUM_SRC_DIR -b $SODIUM_BRANCH
cd $SODIUM_SRC_DIR
./autogen.sh
./configure --prefix=${PREFIX} --host=${HOST} --enable-static --disable-shared
make -j$THREADS
make install

done

