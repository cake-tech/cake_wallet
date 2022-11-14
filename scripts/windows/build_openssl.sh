#!/bin/sh

set -e

. ./config.sh
: '
OPENSSL_FILENAME=openssl-1.1.1q.tar.gz
OPENSSL_FILE_PATH=$CACHEDIR/$OPENSSL_FILENAME
OPENSSL_SRC_DIR=$WORKDIR/openssl-1.1.1q
OPENSSL_SHA256="d7939ce614029cdff0b6c20f0e2e5703158a489a72b2507b8bd51bf8c8fd10ca"

OPENSSL_FILENAME=openssl-1.1.1l.tar.gz
OPENSSL_FILE_PATH=$CACHEDIR/$OPENSSL_FILENAME
OPENSSL_SRC_DIR=$WORKDIR/openssl-1.1.1l
OPENSSL_SHA256="0b7a3e5e59c34827fe0c3a74b7ec8baef302b98fa80088d7f9153aa16fa76bd1"
'
OPENSSL_FILENAME=openssl-1.1.1l.tar.gz
OPENSSL_FILE_PATH=$CACHEDIR/$OPENSSL_FILENAME
OPENSSL_SRC_DIR=$WORKDIR/openssl-1.1.1l
OPENSSL_SHA256="0b7a3e5e59c34827fe0c3a74b7ec8baef302b98fa80088d7f9153aa16fa76bd1"

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

	: '
	if [ ! -z "${MSYSTEM}" ]; then
		./Configure mingw64 \
			no-shared no-tests  \
			--with-zlib-include=${PREFIX}/include \
			--with-zlib-lib=${PREFIX}/lib \
			--prefix=${PREFIX} \
			--openssldir=${PREFIX} \
			OPENSSL_LIBS="-lgdi32 -ladvapi32 -luser32 -lws2_32 -lwsock32 -lcrypt32"
	else
		CROSS_COMPILE="x86_64-w64-mingw32.static-"
		./Configure mingw64 \
			no-shared no-tests \
			--cross-compile-prefix=x86_64-w64-mingw32- \
			--with-zlib-include=${PREFIX}/include \
			--with-zlib-lib=${PREFIX}/lib \
			--prefix=${PREFIX} \
			--openssldir=${PREFIX} \
			OPENSSL_LIBS="-lgdi32 -ladvapi32 -luser32 -lws2_32 -lwsock32 -lcrypt32"
	fi
	'
	CROSS_COMPILE="x86_64-w64-mingw32.static-"
	./Configure mingw64 \
		no-shared no-tests no-capieng no-dso no-dtls1 no-ec_nistp_64_gcc_128 no-gost no-heartbeats no-md2 no-rc5 no-rdrand no-rfc3779 no-sctp no-ssl-trace no-ssl2 no-ssl3 no-unit-test no-weak-ssl-ciphers no-zlib no-zlib-dynamic \
		--cross-compile-prefix=x86_64-w64-mingw32- \
		--with-zlib-include=${PREFIX}/include \
		--with-zlib-lib=${PREFIX}/lib \
		--prefix=${PREFIX} \
		--openssldir=${PREFIX} \
		OPENSSL_LIBS="-llibssl -llibcrypto -llibssl -lcrypt32 -luser32 -lgdi32 -lwsock32 -lws2_32"
		# OPENSSL_LIBS="-lcrypt32 -lws2_32 -lwsock32"
		# OPENSSL_LIBS="-lgdi32 -ladvapi32 -luser32 -lws2_32 -lwsock32 -lcrypt32"
		# OPENSSL_LIBS="-llibssl -llibcrypto -llibssl -lcrypt32 -luser32 -lgdi32 -lwsock32 -lws2_32"
	make -j$THREADS
	make -j$THREADS install_sw
done
