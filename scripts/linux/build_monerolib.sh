#!/bin/sh

. ./config.sh

cd build
mkdir monero_build
MONERO_BUILD=$(pwd)/monero_build

cd $MONERO_BUILD
cmake ../../cmakefiles/monero/${TYPES_OF_BUILD}
make -j$(nproc)
cp libcw_monero.so ../
