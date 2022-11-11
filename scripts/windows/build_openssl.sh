#!/bin/sh

set -e

. ./config.sh
OPENSSL_FILENAME=openssl-1.1.1q.tar.gz
OPENSSL_FILE_PATH=$CACHEDIR/$OPENSSL_FILENAME
OPENSSL_SRC_DIR=$WORKDIR/openssl-1.1.1q
OPENSSL_SHA256="d7939ce614029cdff0b6c20f0e2e5703158a489a72b2507b8bd51bf8c8fd10ca"

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

	#./Configure --cross-compile-prefix=x86_64-w64-mingw32- mingw64 no-shared --with-zlib-include=${WORKDIR}/include --with-zlib-lib=${WORKDIR}/lib --prefix=${WORKDIR}/prefix_x86_64 --openssldir=${WORKDIR}/prefix_x86_64 OPENSSL_LIBS="-lcrypt32 -lws2_32 -lwsock32"
	if [ ! -z "${MSYSTEM}" ]; then
		./Configure mingw64 \
			no-shared no-tests \
			--with-zlib-include=${PREFIX}/include \
			--with-zlib-lib=${PREFIX}/lib \
			--prefix=${PREFIX} \
			--openssldir=${PREFIX} \
			OPENSSL_LIBS="-lcrypt32 -lws2_32 -lwsock32"
	else
		CROSS_COMPILE="x86_64-w64-mingw32.static-"
		./Configure mingw64 \
			no-shared no-tests \
			--cross-compile-prefix=x86_64-w64-mingw32- \
			--with-zlib-include=${PREFIX}/include \
			--with-zlib-lib=${PREFIX}/lib \
			--prefix=${PREFIX} \
			--openssldir=${PREFIX} \
			OPENSSL_LIBS="-lcrypt32 -lws2_32 -lwsock32"
	fi
	make -j$THREADS
	make -j$THREADS install_sw
done
