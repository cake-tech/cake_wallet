#!/bin/sh

. ./config.sh

cd $EXTERNAL_IOS_LIB_DIR
libtool -static -o libboost.a ./boost/*.a
libtool -static -o libhaven.a ./haven/*.a
libtool -static -o libmonero.a ./monero/*.a

CW_HAVEN_EXTERNAL_LIB=../../../cw_haven/ios/External/ios/lib
CW_HAVEN_EXTERNAL_INCLUDE=../../../cw_haven/ios/External/ios/include
CW_MONERO_EXTERNAL=../../../cw_haven/ios/External/ios/lib

mkdir -p $CW_HAVEN_EXTERNAL_INCLUDE
mkdir -p $CW_HAVEN_EXTERNAL_LIB
mkdir -p $CW_MONERO_EXTERNAL

ln -s ./libboost.a $CW_HAVEN_EXTERNAL_LIB
ln -s ./libcrypto.a $CW_HAVEN_EXTERNAL_LIB
ln -s ./libssl.a $CW_HAVEN_EXTERNAL_LIB
ln -s ./libsodium.a $CW_HAVEN_EXTERNAL_LIB
cp ./libhaven.a $CW_HAVEN_EXTERNAL_LIB
cp ../include/haven/* $CW_HAVEN_EXTERNAL_INCLUDE

#ln -s ./libboost.a $CW_HAVEN_EXTERNAL_LIB
#ln -s ./libcrypto.a $CW_HAVEN_EXTERNAL_LIB
#ln -s ./libssl.a $CW_HAVEN_EXTERNAL_LIB
#ln -s ./libsodium.a $CW_HAVEN_EXTERNAL_LIB
#cp ./libhaven.a $CW_HAVEN_EXTERNAL_LIB