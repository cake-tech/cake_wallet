#!/bin/sh

. ./config.sh
SODIUM_SRC_DIR=${WORKDIR}/libsodium
SODIUM_BRANCH=1.0.16

for arch in "aarch" "aarch64" "i686" "x86_64"
do

PREFIX=${WORKDIR}/prefix_${arch}

case $arch in
	"aarch"	) TARGET="arm"
			  CC=armv7a-linux-androideabi${API}-clang
			  CXX=armv7a-linux-androideabi${API}-clang++;;
	"i686"		) TARGET="x86"
			  CC=${arch}-linux-android${API}-clang
			  CXX=${arch}-linux-android${API}-clang++;;
	*		) TARGET="${arch}"
			  CC=${arch}-linux-android${API}-clang
			  CXX=${arch}-linux-android${API}-clang++;;
esac 

HOST="${TARGET}-linux-android"
cd $WORKDIR
rm -rf $SODIUM_SRC_DIR
git clone https://github.com/jedisct1/libsodium.git $SODIUM_SRC_DIR -b $SODIUM_BRANCH
cd $SODIUM_SRC_DIR
./autogen.sh
./configure --prefix=${PREFIX} --host=${HOST} --enable-static --disable-shared
make
make install

done

