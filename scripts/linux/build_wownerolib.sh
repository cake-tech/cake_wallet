#!/bin/sh

. ./config.sh

cd build
mkdir wownero_build
WOWNERO_BUILD=$(pwd)/wownero_build

cd $WOWNERO_BUILD
cmake ../../cmakefiles/wownero/${TYPES_OF_BUILD}
make -j$(nproc)
cp libcw_wownero.so ../

