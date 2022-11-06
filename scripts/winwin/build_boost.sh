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
rm -rf $BOOST_SRC_DIR
tar -xjf $BOOST_FILE_PATH -C $WORKDIR
cp ../user-config.jam $BOOST_SRC_DIR/user-config.jam
cd $BOOST_SRC_DIR
./bootstrap.sh --prefix="${WORKDIR}/prefix_${TYPES_OF_BUILD}" --with-toolset=gcc
./b2 release address-model=64 --verbose link=static runtime-link=static toolset=gcc-mingw target-os=windows --build-dir=windows --stagedir=windows_staging --user-config=user-config.jam --with-chrono --with-date_time --with-filesystem --with-program_options --with-regex --with-serialization --with-system --with-thread --with-locale -sICONV_PATH=${PREFIX} -j$THREADS install

done
