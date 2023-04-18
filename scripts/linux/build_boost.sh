#!/bin/sh

set -e

. ./config.sh

BOOST_SRC_DIR=${EXTERNAL_LINUX_SOURCE_DIR}/boost_1_72_0
BOOST_FILENAME=boost_1_72_0.tar.bz2
BOOST_VERSION=1.72.0
BOOST_FILE_PATH=${EXTERNAL_LINUX_SOURCE_DIR}/$BOOST_FILENAME
BOOST_SHA256="59c9b274bc451cf91a9ba1dd2c7fdcaf5d60b1b3aa83f2c9fa143417cc660722"

if [ ! -e "$BOOST_FILE_PATH" ]; then
	curl -L http://downloads.sourceforge.net/project/boost/boost/${BOOST_VERSION}/${BOOST_FILENAME} > $BOOST_FILE_PATH
fi

echo $BOOST_SHA256 $BOOST_FILE_PATH | sha256sum -c - || exit 1

cd $EXTERNAL_LINUX_SOURCE_DIR
rm -rf $BOOST_SRC_DIR
tar -xvf $BOOST_FILE_PATH -C $EXTERNAL_LINUX_SOURCE_DIR
cd $BOOST_SRC_DIR
./bootstrap.sh --prefix=${EXTERNAL_LINUX_DIR} 
./b2 cxxflags=-fPIC cflags=-fPIC \
     --with-chrono \
     --with-date_time \
     --with-filesystem \
     --with-program_options \
     --with-regex \
     --with-serialization \
     --with-system \
     --with-thread \
     --with-locale \
    link=static \
    install
 
