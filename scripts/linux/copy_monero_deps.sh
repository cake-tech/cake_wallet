#!/bin/bash

WORKDIR="$(pwd)/"build
CW_DIR="$(pwd)"/../../../flutter_libmonero
CW_EXTERNAL_DIR=${CW_DIR}/cw_shared_external/ios/External/android
CW_MONERO_EXTERNAL_DIR=${CW_DIR}/cw_monero/ios/External/android
if [ -z ${TYPES_OF_BUILD+x} ]; then TYPES_OF_BUILD=x86_64; fi

for arch in $TYPES_OF_BUILD
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
INCLUDE_DIR=${CW_EXTERNAL_DIR}/${ABI}/include

mkdir -p $LIB_DIR
mkdir -p $INCLUDE_DIR

cp -r ${PREFIX}/lib/* $LIB_DIR
cp -r ${PREFIX}/include/* $INCLUDE_DIR


mkdir -p ${CW_MONERO_EXTERNAL_DIR}/include

cp $PREFIX/include/monero/wallet2_api.h ${CW_MONERO_EXTERNAL_DIR}/include

done
