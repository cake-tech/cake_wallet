#!/bin/bash

. ./config.sh

EXPAT_VERSION=R_2_4_8
EXPAT_HASH="3bab6c09bbe8bf42d84b81563ddbcf4cca4be838"
EXPAT_SRC_DIR=$WORKDIR/libexpat

for arch in $TYPES_OF_BUILD
do
	case $arch in
		*)
			HOST="${arch}-windows-gnu";;
	esac

	PREFIX=$WORKDIR/prefix_${arch}

	cd $WORKDIR
	rm -rf $EXPAT_SRC_DIR
	git clone https://github.com/libexpat/libexpat.git -b ${EXPAT_VERSION} ${EXPAT_SRC_DIR}
	cd $EXPAT_SRC_DIR
	test `git rev-parse HEAD` = ${EXPAT_HASH} || exit 1
	cd $EXPAT_SRC_DIR/expat

	./buildconf.sh
	#CC=clang CXX=clang++
	CC=x86_64-w64-mingw32-gcc
	CXX=x86_64-w64-mingw32-g++
	if [ ! -z "${MSYSTEM}" ]; then
		HOST=x86_64-w64-mingw32
		#./configure CFLAGS=-fPIC CXXFLAGS=-fPIC --enable-static --disable-shared --prefix=${PREFIX} --host=${HOST}
	else
		CROSS_COMPILE="x86_64-w64-mingw32.static-"
		#./configure CFLAGS=-fPIC CXXFLAGS=-fPIC --enable-static --disable-shared --prefix=${PREFIX} --host=${HOST}
	fi
	#make -j$THREADS
	#make -j$THREADS install
done
