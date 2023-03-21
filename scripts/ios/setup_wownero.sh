#!/bin/sh

cd $EXTERNAL_IOS_LIB_DIR

LIBRANDOMX_PATH=${EXTERNAL_IOS_LIB_DIR}/monero/librandomx.a

if [ -f "$LIBRANDOMX_PATH" ]; then
    cp $LIBRANDOMX_PATH ./wownero
fi

libtool -static -o libboost.a ./libboost_*.a
libtool -static -o libwownero.a ./wownero/*.a

CW_WOWNERO_EXTERNAL_LIB=../../../../../cw_wownero/ios/External/ios/lib
CW_WOWNERO_EXTERNAL_INCLUDE=../../../../../cw_wownero/ios/External/ios/include

mkdir -p $CW_WOWNERO_EXTERNAL_INCLUDE
mkdir -p $CW_WOWNERO_EXTERNAL_LIB

ln ./libboost.a ${CW_WOWNERO_EXTERNAL_LIB}/libboost.a
ln ./libcrypto.a ${CW_WOWNERO_EXTERNAL_LIB}/libcrypto.a
ln ./libssl.a ${CW_WOWNERO_EXTERNAL_LIB}/libssl.a
ln ./libsodium.a ${CW_WOWNERO_EXTERNAL_LIB}/libsodium.a
cp ./libwownero.a $CW_WOWNERO_EXTERNAL_LIB
cp ../include/wownero/* $CW_WOWNERO_EXTERNAL_INCLUDE
cp -r ../include/wownero_seed $CW_WOWNERO_EXTERNAL_INCLUDE
