#!/bin/sh

. ./config.sh
BOOST_FILENAME=boost_1_78_0.tar.bz2
BOOST_FILE_PATH=$CACHEDIR/$BOOST_FILENAME
BOOST_SRC_DIR=$WORKDIR/boost_1_78_0
BOOST_VERSION=1.78.0
BOOST_SHA256="8681f175d4bdb26c52222665793eef08490d7758529330f98d3b29dd0735bccc"

if [ ! -e "$BOOST_FILE_PATH" ]; then
  wget -O $BOOST_FILE_PATH https://boostorg.jfrog.io/artifactory/main/release/1.78.0/source/$BOOST_FILENAME
fi

echo $BOOST_SHA256 $BOOST_FILE_PATH | sha256sum -c - || exit 1

for arch in $TYPES_OF_BUILD
do

PREFIX=$WORKDIR/prefix_${arch}
cd $WORKDIR
#rm -rf $BOOST_SRC_DIR
#tar -xjf $BOOST_FILE_PATH -C $WORKDIR
cd $BOOST_SRC_DIR
./bootstrap.sh --prefix="${WORKDIR}/prefix_${TYPES_OF_BUILD}"
#./b2 cxxflags=-fPIC cflags=-fPIC --verbose --build-type=minimal link=static runtime-link=static --without-context --without-coroutine --build-dir=windows --stagedir=windows threading=multi threadapi=pthread target-os=windows -sICONV_PATH=${PREFIX} -j$THREADS install
./b2 cxxflags=-fPIC cflags=-fPIC --verbose --build-type=minimal link=static runtime-link=static --build-dir=windows --stagedir=windows_staging threading=multi threadapi=pthread target-os=windows -sICONV_PATH=${PREFIX} -j$THREADS install


done
