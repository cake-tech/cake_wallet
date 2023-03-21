#!/bin/bash

WORKDIR="$(pwd)/"build
CW_DIR="$(pwd)"/../../../flutter_libmonero
CW_EXTERNAL_DIR=${CW_DIR}/cw_shared_external/ios/External/android
CW_WOWNERO_EXTERNAL_DIR=${CW_DIR}/cw_wownero/ios/External/android

mkdir -p ${CW_WOWNERO_EXTERNAL_DIR}/include

cp $CW_EXTERNAL_DIR/x86/include/wownero/wallet2_api.h ${CW_WOWNERO_EXTERNAL_DIR}/include
cp -R $CW_EXTERNAL_DIR/x86/include/wownero_seed ${CW_WOWNERO_EXTERNAL_DIR}/include
