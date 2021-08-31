#!/bin/sh

. ./config.sh
BOOST_SRC_DIR=$WORKDIR/boost_1_74_0
BOOST_FILENAME=boost_1_74_0.tar.bz2
BOOST_VERSION=1.74.0

for arch in "aarch" "aarch64" "i686" "x86_64"
do

PREFIX=$WORKDIR/prefix_${arch}

./init_boost.sh $arch $PREFIX $BOOST_SRC_DIR $BOOST_FILENAME $BOOST_VERSION
./finish_boost.sh $arch $PREFIX $BOOST_SRC_DIR $BOOST_SRC_DIR

done
