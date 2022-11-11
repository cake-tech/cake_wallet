#!/bin/sh

. ./config.sh
ICONV_FILENAME=libiconv-1.16.tar.gz
ICONV_FILE_PATH=$CACHEDIR/$ICONV_FILENAME
ICONV_SRC_DIR=$WORKDIR/libiconv-1.16
ICONV_SHA256="e6a1b1b589654277ee790cce3734f07876ac4ccfaecbee8afa0b649cf529cc04"

if [ ! -e "$ICONV_FILE_PATH" ]; then
	curl http://ftp.gnu.org/pub/gnu/libiconv/$ICONV_FILENAME -o $ICONV_FILE_PATH
fi

echo $ICONV_SHA256 $ICONV_FILE_PATH | sha256sum -c - || exit 1

for arch in $TYPES_OF_BUILD
do
	PREFIX=${WORKDIR}/prefix_${arch}

	case $arch in
		"x86_64" )
			HOST="x86_64-windows-gnu";;
		"aarch64" )
			HOST="aarch64-windows-gnu";;
		*	)
			HOST="x86_64-windows-gnu";;
	esac

	if [ ! -z "${MSYSTEM}" ]; then
		HOST=x86_64-w64-mingw32
	fi

	cd $WORKDIR
	rm -rf $ICONV_SRC_DIR
	tar -xzf $ICONV_FILE_PATH -C $WORKDIR
	cd $ICONV_SRC_DIR

	./configure --build=${HOST} --host=${HOST} --prefix=${PREFIX} --disable-rpath
	make -j$THREADS
	make install
done
