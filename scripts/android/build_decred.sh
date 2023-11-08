#!/bin/sh

. ./config.sh
CW_DECRED_DIR=${WORKDIR}/cake_wallet/cw_decred
LIBWALLET_PATH="${WORKDIR}/decred/libwallet"
LIBWALLET_URL="https://github.com/itswisdomagain/libwallet.git"

mkdir -p $LIBWALLET_PATH
git clone $LIBWALLET_URL $LIBWALLET_PATH --branch cgo
cd $LIBWALLET_PATH

for arch in "aarch" "aarch64" "i686" "x86_64"
do

TARGET=""
ABI=""

case $arch in
	"aarch"	)
		TARGET="arm"
		ABI="armeabi-v7a";;
	"aarch64"	)
		TARGET="arm64"
		ABI="arm64-v8a";;
	"i686"		)
		TARGET="386"
		ABI="x86";;
	"x86_64"	)
		TARGET="amd64"
		ABI="x86_64";;
esac

PATH="${TOOLCHAIN_BASE_DIR}_${arch}/bin:${ORIGINAL_PATH}"

rm -rf ./build
CGO_ENABLED=1 GOOS=android GOARCH=${TARGET} CC=clang CXX=clang++ \
go build -buildmode=c-shared -o ./build/libdcrwallet.so ./cgo

DEST_LIB_DIR=${CW_DECRED_DIR}/android/libs/${ABI}
mkdir -p $DEST_LIB_DIR
mv ${LIBWALLET_PATH}/build/libdcrwallet.so $DEST_LIB_DIR

done

HEADER_DIR=$CW_DECRED_DIR/lib/api
mv ${LIBWALLET_PATH}/build/libdcrwallet.h $HEADER_DIR
cd $CW_DECRED_DIR
dart run ffigen
