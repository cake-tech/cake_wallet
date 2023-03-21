#!/bin/bash

( ./build_iconv.sh && ./build_boost.sh ) &
(./build_openssl.sh && ./build_unbound.sh) &
./build_sodium.sh &
./build_zmq.sh &
wait
