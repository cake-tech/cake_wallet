# /bin/bash

WORKDIR=/opt/android
OPENSSL_FILENAME=openssl-1.0.2p.tar.gz
OPENSSL_FILE_PATH=$WORKDIR/$OPENSSL_FILENAME
OPENSSL_SRC_DIR=$WORKDIR/openssl-1.0.2p
ZLIB_FILENAME=zlib-1.2.11.tar.gz
ZLIB_FILE_PATH=$WORKDIR/$ZLIB_FILENAME
ZLIB_SRC_DIR=$WORKDIR/zlib-1.2.11
ORIGINAL_PATH=$PATH
TOOLCHAIN_BASE_DIR=${WORKDIR}/toolchain

wget https://zlib.net/$ZLIB_FILENAME -O $ZLIB_FILE_PATH
tar -xzf $ZLIB_FILE_PATH -C $WORKDIR
cd $ZLIB_SRC_DIR
CC=clang CXX=clang++ ./configure --static
make

wget https://www.openssl.org/source/$OPENSSL_FILENAME -O $OPENSSL_FILE_PATH

for arch in "aarch" "aarch64" "i686" "x86_64"
do

PREFIX=$WORKDIR/prefix_${arch}
PATH="${TOOLCHAIN_BASE_DIR}_${arch}/bin:${ORIGINAL_PATH}"

case $arch in
	"aarch"	) TARGET="armv7";;
	*		) TARGET="${arch}";;
esac 

cd $WORKDIR
rm -rf $OPENSSL_SRC_DIR
tar -xzf $OPENSSL_FILE_PATH -C $WORKDIR
cd $OPENSSL_SRC_DIR
sed -i -e "s/mandroid/target\ ${TARGET}\-linux\-android/" Configure
CC=clang CXX=clang++ ./Configure android no-asm  no-shared --static --with-zlib-include=${WORKDIR}/zlib --with-zlib-lib=${ZLIB_SRC_DIR}  --prefix=${PREFIX} --openssldir=${PREFIX}
make
make install


done


