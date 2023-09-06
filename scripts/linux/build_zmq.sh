#!/bin/sh

. ./config.sh

ZMQ_PATH="${EXTERNAL_LINUX_SOURCE_DIR}/libzmq"
ZMQ_URL="https://github.com/zeromq/libzmq.git"

echo "============================ ZMQ ============================"

echo "Cloning ZMQ from - $ZMQ_URL"
git clone $ZMQ_URL $ZMQ_PATH
cd $ZMQ_PATH
mkdir cmake-build
cd cmake-build
cmake .. -DCMAKE_INSTALL_PREFIX="${EXTERNAL_LINUX_DIR}"
make
make install
