#!/bin/bash
set -x -e
cd "$(dirname "$0")"

HASH=b57584cdafb12d7088689e3b34436db88cb8cd85

if [[ ! -d "pivx_lib/.git" ]]; then
    rm -rf pivx_lib
    git clone https://github.com/Liquid369/pivx_sapling_ffi.git pivx_lib
fi
cd pivx_lib
git fetch -a
git checkout -f $HASH
