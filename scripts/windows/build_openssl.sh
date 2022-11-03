#!/bin/sh

set -e

. ./config.sh
OPENSSL_FILENAME=openssl-1.1.1q.tar.gz
OPENSSL_FILE_PATH=$CACHEDIR/$OPENSSL_FILENAME
OPENSSL_SRC_DIR=$WORKDIR/openssl-1.1.1q
OPENSSL_SHA256="d7939ce614029cdff0b6c20f0e2e5703158a489a72b2507b8bd51bf8c8fd10ca"
ZLIB_DIR=$WORKDIR/zlib
ZLIB_TAG=v1.2.11
ZLIB_COMMIT_HASH="cacf7f1d4e3d44d871b605da3b647f07d718623f"

if [ ! -d "$ZLIB_DIR" ] ; then
  git clone -b $ZLIB_TAG --depth 1 https://github.com/madler/zlib $ZLIB_DIR
fi
cd $ZLIB_DIR
git reset --hard $ZLIB_COMMIT_HASH
./configure --static
make

if [ ! -e "$OPENSSL_FILE_PATH" ]; then
  curl https://www.openssl.org/source/$OPENSSL_FILENAME -o $OPENSSL_FILE_PATH
fi

echo $OPENSSL_SHA256 $OPENSSL_FILE_PATH | sha256sum -c - || exit 1

for arch in $TYPES_OF_BUILD
do
PREFIX=$WORKDIR/prefix_${arch}

cd $WORKDIR
rm -rf $OPENSSL_SRC_DIR
tar -xzf $OPENSSL_FILE_PATH -C $WORKDIR

cd $OPENSSL_SRC_DIR

CROSS_COMPILE="x86_64-w64-mingw32.static-"
./Configure mingw64 \
	no-shared no-tests \
	--cross-compile-prefix=x86_64-w64-mingw32- \
	--with-zlib-include=${PREFIX}/include \
	--with-zlib-lib=${PREFIX}/lib \
	--prefix=${PREFIX} \
	--openssldir=${PREFIX} \
	OPENSSL_LIBS="-lcrypt32 -lws2_32 -lwsock32"
#./Configure --cross-compile-prefix=x86_64-w64-mingw32- mingw64 no-shared --with-zlib-include=${WORKDIR}/include --with-zlib-lib=${WORKDIR}/lib --prefix=${WORKDIR}/prefix_x86_64 --openssldir=${WORKDIR}/prefix_x86_64 OPENSSL_LIBS="-lcrypt32 -lws2_32 -lwsock32"
make -j$THREADS
make -j$THREADS install_sw

done
