# /bin/bash

WORKDIR=/opt/android
CW_DIR=${WORKDIR}/cake_wallet
CW_EXRTERNAL_DIR=${CW_DIR}/cw_monero/ios/External/android

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

LIB_DIR=${CW_EXRTERNAL_DIR}/${ABI}/lib
INCLUDE_DIR=${CW_EXRTERNAL_DIR}/${ABI}/include

mkdir -p $LIB_DIR
mkdir -p $INCLUDE_DIR

cp -r ${PREFIX}/lib/* $LIB_DIR
cp -r ${PREFIX}/include/* $INCLUDE_DIR


done
