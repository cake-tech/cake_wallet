#!/bin/sh

. ./config.sh

cd build
mkdir monero_build
mkdir wownero_build
MONERO_BUILD=$(pwd)/monero_build
WOWNERO_BUILD=$(pwd)/wownero_build

cd $MONERO_BUILD
cmake ../../cmakefiles/monero/${TYPES_OF_BUILD}
make -j$(nproc)
cp libcw_monero.so ../

cd $WOWNERO_BUILD
cmake ../../cmakefiles/wownero/${TYPES_OF_BUILD}
make -j$(nproc)
cp libcw_wownero.so ../
