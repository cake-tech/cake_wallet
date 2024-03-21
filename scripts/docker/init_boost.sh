#!/bin/bash

ARCH=$1
PREFIX=$2
BOOST_SRC_DIR=$3
BOOST_FILENAME=$4
BOOST_VERSION=$5
BOOST_FILE_PATH=$WORKDIR/$BOOST_FILENAME
BOOST_SHA256="59c9b274bc451cf91a9ba1dd2c7fdcaf5d60b1b3aa83f2c9fa143417cc660722"

if [ ! -e "$BOOST_FILE_PATH" ]; then
	curl -L http://downloads.sourceforge.net/project/boost/boost/${BOOST_VERSION}/${BOOST_FILENAME} > $BOOST_FILE_PATH
fi

echo $BOOST_SHA256 $BOOST_FILE_PATH | sha256sum -c - || exit 1

cd $WORKDIR
rm -rf $BOOST_SRC_DIR
rm -rf $PREFIX/include/boost
tar -xvf $BOOST_FILE_PATH -C $WORKDIR
cd $BOOST_SRC_DIR
./bootstrap.sh --prefix=${PREFIX}
