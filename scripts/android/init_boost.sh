# /bin/bash

WORKDIR=/opt/android
ARCH=$1
PREFIX="${WORKDIR}/prefix_${ARCH}"
BOOST_FILENAME=boost_1_68_0.tar.bz2
BOOST_FILE_PATH=$WORKDIR/$BOOST_FILENAME
BOOST_SRC_DIR=$WORKDIR/boost_1_68_0

if [ ! -e "$BOOST_FILE_PATH" ]; then
	wget https://dl.bintray.com/boostorg/release/1.68.0/source/$BOOST_FILENAME -O $BOOST_FILE_PATH
fi

cd $WORKDIR
rm -rf $BOOST_SRC_DIR
tar -xvf $BOOST_FILE_PATH -C $WORKDIR
cd $BOOST_SRC_DIR
./bootstrap.sh --prefix=${PREFIX}
