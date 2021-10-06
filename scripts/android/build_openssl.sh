#!/bin/sh

. ./config.sh
OPENSSL_FILENAME=openssl-1.1.1k.tar.gz
OPENSSL_FILE_PATH=$WORKDIR/$OPENSSL_FILENAME
OPENSSL_SRC_DIR=$WORKDIR/openssl-1.1.1k
OPENSSL_SHA256="892a0875b9872acd04a9fde79b1f943075d5ea162415de3047c327df33fbaee5"
ZLIB_FILENAME=zlib-1.2.11.tar.gz
ZLIB_FILE_PATH=$WORKDIR/$ZLIB_FILENAME
ZLIB_SRC_DIR=$WORKDIR/zlib-1.2.11
ZLIB_SHA256="c3e5e9fdd5004dcb542feda5ee4f0ff0744628baf8ed2dd5d66f8ca1197cb1a1"

curl https://zlib.net/$ZLIB_FILENAME -o $ZLIB_FILE_PATH
echo $ZLIB_SHA256 $ZLIB_FILE_PATH | sha256sum -c - || exit 1

tar -xzf $ZLIB_FILE_PATH -C $WORKDIR
cd $ZLIB_SRC_DIR
CC=clang CXX=clang++ ./configure --static
make

curl https://www.openssl.org/source/$OPENSSL_FILENAME -o $OPENSSL_FILE_PATH
echo $OPENSSL_SHA256 $OPENSSL_FILE_PATH | sha256sum -c - || exit 1

for arch in "aarch" "aarch64" "i686" "x86_64"
do
PREFIX=$WORKDIR/prefix_${arch}

case $arch in
	"aarch")   CLANG=armv7a-linux-androideabi${API}-clang
		   CXXLANG=armv7a-linux-androideabi${API}-clang++
		   X_ARCH="android-arm";;
	"aarch64") CLANG=${arch}-linux-android${API}-clang
		   CXXLANG=${arch}-linux-android${API}-clang++
		   X_ARCH="android-arm64";;
	"i686")    CLANG=${arch}-linux-android${API}-clang
		   CXXLANG=${arch}-linux-android${API}-clang++
		   X_ARCH="android-x86";;
	"x86_64")  CLANG=${arch}-linux-android${API}-clang
		   CXXLANG=${arch}-linux-android${API}-clang++
		   X_ARCH="android-x86_64";;
	*)	   CLANG=${arch}-linux-android${API}-clang
		   CXXLANG=${arch}-linux-android${API}-clang++
		   X_ARCH="android-${arch}";;
esac 	

cd $WORKDIR
rm -rf $OPENSSL_SRC_DIR
tar -xzf $OPENSSL_FILE_PATH -C $WORKDIR
cd $OPENSSL_SRC_DIR
./Configure CC=${CLANG} CXX=${CXXLANG} ${X_ARCH} \
	no-asm no-shared --static \
	--with-zlib-include=${PREFIX}/include \
	--with-zlib-lib=${PREFIX}/lib \
	--prefix=${PREFIX} \
	--openssldir=${PREFIX} \
	-D__ANDROID_API__=$API
sed -i 's/CNF_EX_LIBS=-ldl -pthread//g;s/BIN_CFLAGS=-pie $(CNF_CFLAGS) $(CFLAGS)//g' Makefile
make -j4
make install

done

