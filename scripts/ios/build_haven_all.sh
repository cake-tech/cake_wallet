#!/bin/sh

. ./config.sh
./install_missing_headers.sh
./build_openssl.sh
./build_boost.sh
./build_sodium.sh
./build_zmq.sh
./build_haven.sh