#!/bin/sh

set -e

. ./config.sh

BOOST_SRC_DIR=${EXTERNAL_LINUX_SOURCE_DIR}/boost_1_82_0
BOOST_FILENAME=boost_1_82_0.tar.bz2
BOOST_VERSION=1.82.0
BOOST_FILE_PATH=${EXTERNAL_LINUX_SOURCE_DIR}/$BOOST_FILENAME
BOOST_SHA256="a6e1ab9b0860e6a2881dd7b21fe9f737a095e5f33a3a874afc6a345228597ee6"

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
 
