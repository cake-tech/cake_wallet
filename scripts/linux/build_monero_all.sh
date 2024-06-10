#!/bin/sh


. ./config.sh

./build_openssl.sh
./build_iconv.sh
./build_boost.sh
./build_zmq.sh
./build_expat.sh
./build_unbound.sh
./build_sodium.sh
./build_monero.sh
