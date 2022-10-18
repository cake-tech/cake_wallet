#!/bin/sh

. ./config.sh
BOOST_SRC_DIR=$WORKDIR/boost_1_78_0
BOOST_FILENAME=boost_1_78_0.tar.bz2
BOOST_VERSION=1.78.0

for arch in $TYPES_OF_BUILD
do

PREFIX=$WORKDIR/prefix_${arch}
# put the outputs into dev/null since it overrides githubs workflow test log
./init_boost.sh $arch $PREFIX $BOOST_SRC_DIR $BOOST_FILENAME $BOOST_VERSION  > /dev/null
./finish_boost.sh $arch $PREFIX $BOOST_SRC_DIR $BOOST_SRC_DIR  > /dev/null

done
