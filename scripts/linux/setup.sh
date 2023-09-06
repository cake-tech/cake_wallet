#!/bin/sh

. ./config.sh

CW_EXTERNAL_DIR=${CW_ROOT}/cw_monero/ios/External/linux
CW_EXTERNAL_DIR_INCLUDE=${CW_EXTERNAL_DIR}/include

mkdir -p $CW_EXTERNAL_DIR_INCLUDE
cp $EXTERNAL_LINUX_INCLUDE_DIR/monero/wallet2_api.h $CW_EXTERNAL_DIR_INCLUDE
