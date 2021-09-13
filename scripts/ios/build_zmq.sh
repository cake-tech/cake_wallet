#!/bin/sh

. ./config.sh

ZMQ_PATH="${EXTERNAL_IOS_SOURCE_DIR}/libzmq"
ZMQ_URL="https://github.com/zeromq/libzmq.git"

echo "============================ ZMQ ============================"

echo "Cloning ZMQ from - $ZMQ_URL"
git clone $ZMQ_URL $ZMQ_PATH

cp ${ZMQ_PATH}/include/* $EXTERNAL_IOS_INCLUDE_DIR