#!/bin/bash

set -x -e

cd "$(dirname "$0")"

if [[ ! -d "monero_c" ]];
then
    git clone https://github.com/mrcyjanek/monero_c --branch master
    cd monero_c
    git checkout fffd22288aa9384add744a04251f68ec65124980
    git reset --hard
    git submodule update --init --force --recursive
    ./apply_patches.sh monero
    ./apply_patches.sh wownero
else
    cd monero_c
fi

if [[ ! -f "monero/.patch-applied" ]];
then
    ./apply_patches.sh monero
fi

if [[ ! -f "wownero/.patch-applied" ]];
then
    ./apply_patches.sh wownero
fi
cd ..

echo "monero_c source prepared".
