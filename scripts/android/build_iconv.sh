# /bin/bash

export WORKDIR=/opt/android
export ICONV_FILENAME=libiconv-1.15.tar.gz
export ICONV_FILE_PATH=$WORKDIR/$ICONV_FILENAME
export ICONV_SRC_DIR=$WORKDIR/libiconv-1.15

wget http://ftp.gnu.org/pub/gnu/libiconv/$ICONV_FILENAME -O $ICONV_FILE_PATH

ORIGINAL_PATH=$PATH
TOOLCHAIN_BASE_DIR=${WORKDIR}/toolchain

for arch in aarch aarch64 i686 x86_64
do

PREFIX=${WORKDIR}/prefix_${arch}
PATH="${TOOLCHAIN_BASE_DIR}_${arch}/bin:${ORIGINAL_PATH}"

case $arch in
	"aarch"	)
		CLANG=arm-linux-androideabi-clang
		CXXLANG=arm-linux-androideabi-clang++
		HOST="arm-linux-android";;
	*		)
		CLANG=${arch}-linux-android-clang
		CXXLANG=${arch}-linux-android-clang++
		HOST="${arch}-linux-android";;
esac 

cd $WORKDIR
rm -rf $ICONV_SRC_DIR
tar -xzf $ICONV_FILE_PATH -C $WORKDIR
cd $ICONV_SRC_DIR
CC=${CLANG} CXX=${CXXLANG} ./configure --build=x86_64-linux-gnu --host=${HOST} --prefix=${PREFIX} --disable-rpath
make
make install

done
