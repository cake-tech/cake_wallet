#!/bin/bash

. ./config.sh

EXPAT_VERSION=R_2_4_8
EXPAT_HASH="3bab6c09bbe8bf42d84b81563ddbcf4cca4be838"
EXPAT_SRC_DIR=$WORKDIR/libexpat

for arch in "aarch" "aarch64" "i686" "x86_64"
do
PREFIX=$WORKDIR/prefix_${arch}
TOOLCHAIN=${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64
PATH="${TOOLCHAIN_BASE_DIR}_${arch}/bin:${ORIGINAL_PATH}"

cd $WORKDIR
rm -rf $EXPAT_SRC_DIR
git clone https://github.com/libexpat/libexpat.git -b ${EXPAT_VERSION} ${EXPAT_SRC_DIR}
cd $EXPAT_SRC_DIR
test `git rev-parse HEAD` = ${EXPAT_HASH} || exit 1
cd $EXPAT_SRC_DIR/expat

case $arch in
	"aarch")   HOST="arm-linux-androideabi";;
	"i686")    HOST="x86-linux-android";;
	*)	       HOST="${arch}-linux-android";;
esac 

./buildconf.sh
CC=clang CXX=clang++ ./configure --enable-static --disable-shared --prefix=${PREFIX} --host=${HOST}
make -j$THREADS
make -j$THREADS install
done

UNBOUND_VERSION=release-1.16.2
UNBOUND_HASH="cbed768b8ff9bfcf11089a5f1699b7e5707f1ea5"
UNBOUND_SRC_DIR=$WORKDIR/unbound-1.16.2

for arch in "aarch" "aarch64" "i686" "x86_64"
do
PREFIX=$WORKDIR/prefix_${arch}
TOOLCHAIN=${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64

case $arch in
	"aarch")   TOOLCHAIN_BIN_PATH=${TOOLCHAIN_BASE_DIR}_${arch}/arm-linux-androideabi/bin;;
	*)	       TOOLCHAIN_BIN_PATH=${TOOLCHAIN_BASE_DIR}_${arch}/${arch}-linux-android/bin;;
esac 

PATH="${TOOLCHAIN_BIN_PATH}:${TOOLCHAIN_BASE_DIR}_${arch}/bin:${ORIGINAL_PATH}"
echo $PATH
cd $WORKDIR
rm -rf $UNBOUND_SRC_DIR
git clone https://github.com/NLnetLabs/unbound.git -b ${UNBOUND_VERSION} ${UNBOUND_SRC_DIR}
cd $UNBOUND_SRC_DIR
test `git rev-parse HEAD` = ${UNBOUND_HASH} || exit 1

case $arch in
	"aarch")   HOST="arm-linux-androideabi";;
	"i686")    HOST="x86-linux-android";;
	*)	       HOST="${arch}-linux-android";;
esac

CC=clang CXX=clang++ ./configure --prefix=${PREFIX} --host=${HOST} --enable-static --disable-shared --disable-flto --with-ssl=${PREFIX} --with-libexpat=${PREFIX}
make -j$THREADS
make -j$THREADS install
done
