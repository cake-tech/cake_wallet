# /bin/bash

WORKDIR=/opt/android
ARCH=$1
PREFIX="${WORKDIR}/prefix_${ARCH}"
BOOST_SRC_DIR=$WORKDIR/boost_1_68_0

cd $BOOST_SRC_DIR
./b2 --build-type=minimal link=static runtime-link=static --with-chrono --with-date_time --with-filesystem --with-program_options --with-regex --with-serialization --with-system --with-thread --with-locale --build-dir=android --stagedir=android toolset=clang threading=multi threadapi=pthread target-os=android -sICONV_PATH=${PREFIX} install
