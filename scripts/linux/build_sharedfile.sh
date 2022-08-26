#!/bin/sh

. ./config.sh
cd build
cmake ../cmakefiles/${TYPES_OF_BUILD}
make -j$(nproc)


