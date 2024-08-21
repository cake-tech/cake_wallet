#!/bin/sh
set -x -e

cd "$(dirname "$0")"

NPROC="-j$(sysctl -n hw.logicalcpu)"
MONERO_LIBS=""
WOWNERO_LIBS=""
MONEROC_RELEASE_DIR="../monero_c/release/monero"
WOWNEROC_RELEASE_DIR="../monero_c/release/wownero"

../prepare_moneroc.sh

# NOTE: -j1 is intentional. Otherwise you will run into weird behaviour on macos
if [[ ! "x$USE_DOCKER" == "x" ]];
then
    for COIN in monero wownero;
    do
        pushd ../monero_c
            echo "unsupported!"
            exit 1
        popd
    done
else
    if [[ "x$1" == "xuniversal" ]]; then
	ARCHS=(x86_64 arm64)
    else
	ARCHS=$(uname -m)
    fi
    for COIN in monero wownero;
    do
        MONERO_LIBS=""
        WOWNERO_LIBS=""
	for ARCH in "${ARCHS[@]}";
	do
	    if [[ "$ARCH" == "arm64" ]]; then
		export HOMEBREW_PREFIX=/opt/homebrew
		HOST="aarch64-host-apple-darwin"
	    else
		export HOMEBREW_PREFIX=/usr/local
		HOST="${ARCH}-host-apple-darwin"
	    fi

            MONERO_LIBS="$MONERO_LIBS -arch ${ARCH} ${MONEROC_RELEASE_DIR}/${HOST}_libwallet2_api_c.dylib"
            WOWNERO_LIBS="$WOWNERO_LIBS -arch ${ARCH} ${WOWNEROC_RELEASE_DIR}/${HOST}_libwallet2_api_c.dylib"

            if [[ ! $(uname -m) == $ARCH ]]; then
                PRC="arch -${ARCH}"
            else
                PRC=""
            fi

            pushd ../monero_c
                $PRC ./build_single.sh ${COIN} ${HOST} $NPROC
                unxz -f ./release/${COIN}/${HOST}_libwallet2_api_c.dylib.xz
	    popd
	done
    done
fi

lipo -create ${MONERO_LIBS} -output "${MONEROC_RELEASE_DIR}/host-apple-darwin_libwallet2_api_c.dylib"
lipo -create ${WOWNERO_LIBS} -output "${WOWNEROC_RELEASE_DIR}/host-apple-darwin_libwallet2_api_c.dylib"
