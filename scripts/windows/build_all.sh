#!/bin/bash

mkdir -p build
mkdir -p cache
#./build_iconv.sh
./build_boost.sh
#./build_zlib.sh
./build_openssl.sh
./build_sodium.sh
#./build_expat.sh
./build_unbound.sh
./build_zmq.sh
./build_monero.sh
./build_wownero.sh
./build_wownero_seed.sh
./build_sharedfile.sh
