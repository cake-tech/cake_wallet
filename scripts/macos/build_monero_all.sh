#!/bin/sh
set -x -e

cd "$(dirname "$0")"

NPROC="-j$(sysctl -n hw.logicalcpu)"
LIBS=""
MONEROC_RELEASE_DIR="../monero_c/release/monero"

../prepare_moneroc.sh

# NOTE: -j1 is intentional. Otherwise you will run into weird behaviour on macos
if [[ ! "x$USE_DOCKER" == "x" ]];
then
    for COIN in monero;
    do
        pushd ../monero_c
            echo "unsupported!"
            exit 1
        popd
    done
else
    if [[ "x$1" == "xuniversal" ]]; then
	ARCHS=(arm64 x86_64)
    else
	ARCHS=$(uname -m)
    fi
    for COIN in monero;
    do
	for ARCH in "${ARCHS[@]}";
	do
	    if [[ "$ARCH" == "arm64" ]]; then
		export HOMEBREW_PREFIX=/opt/homebrew
		HOST="aarch64-host-apple-darwin"
	    else
		export HOMEBREW_PREFIX=/usr/local
		HOST="${ARCH}-host-apple-darwin"
	    fi

	    LIBS="${LIBS} -arch ${ARCH} ${MONEROC_RELEASE_DIR}/${HOST}_libwallet2_api_c.dylib"

	    if [[ ! $(uname -m) == $ARCH ]]; then
		PRC="arch -${ARCH}"
	    fi

            pushd ../monero_c
            $PRC ./build_single.sh ${COIN} ${HOST} $NPROC
	    unxz -f ./release/monero/${HOST}_libwallet2_api_c.dylib.xz

            popd
	 done
    done
fi

lipo -create ${LIBS} -output "${MONEROC_RELEASE_DIR}/host-apple-darwin_libwallet2_api_c.dylib"
