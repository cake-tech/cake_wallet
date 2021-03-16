# /bin/bash

WORKDIR=/opt/android
TOOLCHAIN_BASE_DIR=${WORKDIR}/toolchain
ZMQ_SRC_DIR=$WORKDIR/libzmq
ZMQ_BRANCH=master
ZMQ_COMMIT_HASH=501d0815bf2b0abb93be8214fc66519918ef6c40
ORIGINAL_PATH=$PATH


for arch in "aarch" "aarch64" "i686" "x86_64"
do

PREFIX=$WORKDIR/prefix_${arch}
PATH="${TOOLCHAIN_BASE_DIR}_${arch}/bin:${ORIGINAL_PATH}"

case $arch in
	"aarch"	) TARGET="arm";;
	"i686"		) TARGET="x86";;
	*		) TARGET="${arch}";;
esac 

HOST="${TARGET}-linux-android"
cd $WORKDIR
rm -rf $ZMQ_SRC_DIR
git clone https://github.com/zeromq/libzmq.git ${ZMQ_SRC_DIR} -b ${ZMQ_BRANCH}
cd $ZMQ_SRC_DIR
git checkout ${ZMQ_COMMIT_HASH}
./autogen.sh
CC=clang CXX=clang++ ./configure --prefix=${PREFIX} --host=${HOST} --enable-static --disable-shared
make
make install

done
