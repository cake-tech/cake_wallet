#!/bin/bash

WORKDIR=/opt/android
#CW_DIR=${WORKDIR}/zano_cake_wallet
CW_DIR=$(cd ../.. && pwd)
echo "CW_DIR: $CW_DIR"
CW_EXTERNAL_DIR=${CW_DIR}/cw_shared_external/ios/External/android
for arch in "aarch" "aarch64" "i686" "x86_64"
do

PREFIX=${WORKDIR}/prefix_${arch}
ABI=""

case $arch in
	"aarch"	)
		ABI="armeabi-v7a";;
	"aarch64"	)
		ABI="arm64-v8a";;
	"i686"		)
		ABI="x86";;
	"x86_64"	)
		ABI="x86_64";;
esac

LIB_DIR=${CW_EXTERNAL_DIR}/${ABI}/lib

mkdir -p $LIB_DIR

cp -r ${PREFIX}/lib/* $LIB_DIR

mkdir -p ${CW_DIR}/cw_shared_external/ios/External/ios/sources/zano/src/wallet/
cp ${WORKDIR}/zano/src/wallet/plain_wallet_api.h ${CW_DIR}/cw_shared_external/ios/External/ios/sources/zano/src/wallet/

done
