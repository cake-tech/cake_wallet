#!/bin/sh

. ./config.sh

SEED_DIR=$WORKDIR/seed
SEED_TAG=0.3.0
SEED_COMMIT_HASH="ef6910b6bb3b61757c36e2e5db0927d75f1731c8"

FLAGS=""
DEST_LIB_DIR=${PREFIX}/lib/
DEST_INCLUDE_DIR=${PREFIX}/include/
export CMAKE_INCLUDE_PATH="${PREFIX}/include"
export CMAKE_LIBRARY_PATH="${PREFIX}/lib"

BUILD_64=ON
TAG="win-x86_64"
ARCH="x86-64"
ARCH_ABI="x86_64"

cd $WORKDIR

rm -rf $SEED_DIR
git clone -b $SEED_TAG --depth 1 https://git.wownero.com/wowlet/wownero-seed.git $SEED_DIR
cd $SEED_DIR
git reset --hard $SEED_COMMIT_HASH

CFLAGS=-fPIC
CXXFLAGS=-fPIC
x86_64-w64-mingw32.static-cmake \
	-Bbuild \
	-DCMAKE_INSTALL_PREFIX=${PREFIX} \
	ARCH=${ARCH} \
	-D CMAKE_BUILD_TYPE=Release $FLAGS .

make -Cbuild -j$THREADS
make -Cbuild install
