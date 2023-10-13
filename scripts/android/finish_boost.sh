#!/bin/sh

ARCH=$1
PREFIX=$2
BOOST_SRC_DIR=$3

cd $BOOST_SRC_DIR

./b2 --build-type=minimal link=static runtime-link=static --with-chrono --with-date_time --with-filesystem --with-program_options --with-regex --with-serialization --with-system --with-thread --with-locale --with-log --build-dir=android --stagedir=android toolset=clang threading=multi threadapi=pthread target-os=android -sICONV_PATH=${PREFIX} -j$THREADS install
