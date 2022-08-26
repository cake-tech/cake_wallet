#!/bin/sh

. ./config.sh
printf $(git log -1 --pretty=format:"%h") >> build/git_commit_version.txt
cd $EXTERNAL_IOS_LIB_DIR
libtool -static -o libboost.a ./libboost_*.a

libtool -static -o libmonero.a ./monero/*.a


CW_MONERO_EXTERNAL_LIB=../../../../../cw_monero/ios/External/ios/lib
CW_MONERO_EXTERNAL_INCLUDE=../../../../../cw_monero/ios/External/ios/include

mkdir -p $CW_MONERO_EXTERNAL_INCLUDE
mkdir -p $CW_MONERO_EXTERNAL_LIB



ln ./libboost.a ${CW_MONERO_EXTERNAL_LIB}/libboost.a
ln ./libcrypto.a ${CW_MONERO_EXTERNAL_LIB}/libcrypto.a
ln ./libssl.a ${CW_MONERO_EXTERNAL_LIB}/libssl.a
ln ./libsodium.a ${CW_MONERO_EXTERNAL_LIB}/libsodium.a
ln ./libunbound.a ${CW_MONERO_EXTERNAL_LIB}/libunbound.a
cp ./libmonero.a $CW_MONERO_EXTERNAL_LIB
cp ../include/monero/* $CW_MONERO_EXTERNAL_INCLUDE