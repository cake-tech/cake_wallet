#!/bin/sh

. ./config.sh
BOOST_FILENAME=boost_1_78_0.tar.bz2
BOOST_FILE_PATH=$CACHEDIR/$BOOST_FILENAME
BOOST_SRC_DIR=$WORKDIR/boost_1_78_0
BOOST_VERSION=1.78.0
BOOST_SHA256="8681f175d4bdb26c52222665793eef08490d7758529330f98d3b29dd0735bccc"

if [ ! -e "$BOOST_FILE_PATH" ]; then
	wget -O $BOOST_FILE_PATH https://boostorg.jfrog.io/artifactory/main/release/1.78.0/source/$BOOST_FILENAME
fi

echo $BOOST_SHA256 $BOOST_FILE_PATH | sha256sum -c - || exit 1

for arch in $TYPES_OF_BUILD
do
	PREFIX=$WORKDIR/prefix_${arch}
	cd $WORKDIR
	rm -rf $BOOST_SRC_DIR
	tar -xjf $BOOST_FILE_PATH -C $WORKDIR
	cp ../user-config.jam $BOOST_SRC_DIR/user-config.jam
	cd $BOOST_SRC_DIR

	./bootstrap.sh --prefix="${WORKDIR}/prefix_${arch}" --with-toolset=gcc
	: '
	if [ ! -z "${MSYSTEM}" ]; then
		./b2 release \
			address-model=64 \
			--prefix="${WORKDIR}/prefix_${arch}" \
			--verbose \
			link=static \
			runtime-link=static \
			target-os=windows \
			--build-dir=windows \
			--stagedir=windows_staging \
			--with-chrono \
			--with-date_time \
			--with-filesystem \
			--with-program_options \
			--with-regex \
			--with-serialization \
			--with-system \
			--with-thread \
			--with-locale \
			-sICONV_PATH=${PREFIX} \
			-j$THREADS install
	else'
		CC=x86_64-w64-mingw32-gcc
		CXX=x86_64-w64-mingw32-g++
		HOST=x86_64-w64-mingw32
		CROSS_COMPILE="x86_64-w64-mingw32.static-"
		./b2 release \
			cxxflags=-fPIC \
			cflags=-fPIC \
			--layout=tagged \
			--build-type=minimal \
			threading=multi \
			link=static \
			-sNO_BZIP2=1 \
			-sNO_ZLIB=1 \
			binary-format=pe \
			target-os=windows \
			threadapi=win32 \
			runtime-link=static \
			address-model=64 \
			--verbose \
			runtime-link=static \
			toolset=gcc-mingw \
			--build-dir=windows \
			--stagedir=windows \
			--user-config=user-config.jam \
			--with-chrono \
			--with-date_time \
			--with-filesystem \
			--with-program_options \
			--with-regex \
			--with-serialization \
			--with-system \
			--with-thread \
			--with-locale \
			-sICONV_PATH=${PREFIX} \
			-j$THREADS install
			: '
			cxxflags=-fPIC \
			cflags=-fPIC \
			--verbose \
			--build-type=minimal \
			link=static \
			runtime-link=static \
			--with-chrono \
			--with-date_time \
			--with-filesystem \
			--with-program_options \
			--with-regex \
			--with-serialization \
			--with-system \
			--with-thread \
			--with-locale \
			--build-dir=android \
			--stagedir=android \
			threading=multi \
			threadapi=pthread \
			target-os=linux \
			-sICONV_PATH=${PREFIX} \
			-j$THREADS install
	fi'
done
