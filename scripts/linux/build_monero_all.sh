#!/bin/bash
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/functions.sh"

set -x -e

cd "$(dirname "$0")"

../prepare_moneroc.sh

if [[ -f "/usr/bin/protoc" ]]; then
    echo "[!] /usr/bin/protoc found - please get rid of it before building."
    echo "or alternatively fix it somewhere in simplybs/monero_c"
    exit 1
fi

for COIN in monero wownero;
do
    pushd ../monero_c
        for target in x86_64-linux-gnu aarch64-linux-gnu;
        do
            ./build_single.sh ${COIN} $target -j$MAKE_JOB_COUNT
        done
    popd
done
