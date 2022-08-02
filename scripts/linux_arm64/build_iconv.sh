#!/bin/sh

. ./config.sh
export ICONV_FILENAME=libiconv-1.16.tar.gz
export ICONV_FILE_PATH=$WORKDIR/$ICONV_FILENAME
export ICONV_SRC_DIR=$WORKDIR/libiconv-1.16
ICONV_SHA256="e6a1b1b589654277ee790cce3734f07876ac4ccfaecbee8afa0b649cf529cc04"

curl http://ftp.gnu.org/pub/gnu/libiconv/$ICONV_FILENAME -o $ICONV_FILE_PATH
echo $ICONV_SHA256 $ICONV_FILE_PATH | sha256sum -c - || exit 1

for arch in "aarch64"
do

PREFIX=${WORKDIR}/prefix_${arch}

case $arch in
	"aarch"	)
        HOST="aarch64-linux-gnu";;
	*		)
		HOST="aarch64-linux-gnu";;
esac 

cd $WORKDIR
rm -rf $ICONV_SRC_DIR
tar -xzf $ICONV_FILE_PATH -C $WORKDIR
cd $ICONV_SRC_DIR
./configure --build=aarch64-linux-gnu --host=${HOST} --prefix=${PREFIX} --disable-rpath
make -j$THREADS
make install

done

