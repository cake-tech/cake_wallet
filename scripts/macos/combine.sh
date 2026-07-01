#!/bin/sh

. ./config.sh

cd $EXTERNAL_DIR
mkdir -p $EXTERNAL_MACOS_LIB_DIR

EXTERNAL_DIR_MACOS_ARM=${EXTERNAL_DIR}/macos-arm/lib
EXTERNAL_DIR_MACOS_X86_64=${EXTERNAL_DIR}/macos-x86_64/lib

LIBS=(libboost.a libcrypto.a libssl.a libsodium.a libunbound.a libmonero.a)

for lib in ${LIBS[@]}; do
	echo ${EXTERNAL_DIR_MACOS_ARM}/$lib
	echo ${EXTERNAL_DIR_MACOS_X86_64}/$lib
	lipo -create -arch arm64 ${EXTERNAL_DIR_MACOS_ARM}/$lib -arch x86_64 ${EXTERNAL_DIR_MACOS_X86_64}/$lib -output ${EXTERNAL_MACOS_LIB_DIR}/$lib; 
done