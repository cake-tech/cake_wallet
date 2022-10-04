#!/bin/sh

. ./config.sh
# already done with build_monero_all.sh
#./install_missing_headers.sh
#./build_openssl.sh
#./build_boost.sh
#./build_sodium.sh
#./build_zmq.sh
./build_wownero.sh
./build_wownero_seed.sh