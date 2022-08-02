#!/bin/sh

ARCH=$1
PREFIX=$2
BOOST_SRC_DIR=$3

cd $BOOST_SRC_DIR

./b2 cxxflags=-fPIC cflags=-fPIC --verbose --build-type=minimal link=static runtime-link=static --with-chrono --with-date_time --with-filesystem --with-program_options --with-regex --with-serialization --with-system --with-thread --with-locale --build-dir=android --stagedir=android threading=multi threadapi=pthread target-os=linux -sICONV_PATH=${PREFIX} -j$THREADS install
