#!/bin/bash

. ./config.sh

UNBOUND_VERSION=release-1.16.2
UNBOUND_HASH="cbed768b8ff9bfcf11089a5f1699b7e5707f1ea5"
UNBOUND_SRC_DIR=$WORKDIR/unbound-1.16.2

for arch in $TYPES_OF_BUILD
do
	PREFIX=$WORKDIR/prefix_${arch}

	cd $WORKDIR
	rm -rf $UNBOUND_SRC_DIR
	git clone https://github.com/NLnetLabs/unbound.git -b ${UNBOUND_VERSION} ${UNBOUND_SRC_DIR}
	cd $UNBOUND_SRC_DIR
	test `git rev-parse HEAD` = ${UNBOUND_HASH} || exit 1

	if [ ! -z "${MSYSTEM}" ]; then
		./configure \
			CFLAGS=-fPIC \
			CXXFLAGS=-fPIC \
			--prefix=${PREFIX} \
			--host=${HOST} \
			--enable-static \
			--disable-shared \
			--disable-flto \
			--enable-static-openssl \
			--with-openssl-includes=${PREFIX} \
			--with-ssl=${PREFIX} \
			--with-libexpat=${PREFIX}
	else
		CROSS_COMPILE="x86_64-w64-mingw32.static-"
		./configure \
			CFLAGS=-fPIC \
			CXXFLAGS=-fPIC \
			--prefix=${PREFIX} \
			--host=${HOST} \
			--enable-static \
			--disable-shared \
			--disable-flto \
			--enable-static-openssl \
			--with-ssl=${PREFIX} \
			--with-libexpat=${PREFIX}
	fi
	make -j$THREADS
	make -j$THREADS install
done
