#!/bin/bash

set -x -e

cd "$(dirname "$0")"

if [[ ! -d "monero_c/.git" ]];
then
    rm -rf monero_c
    git clone https://github.com/mrcyjanek/monero_c --branch master monero_c
    cd monero_c
    # NOTE: Make sure to update monero_c prebuilds link in workflow files
    # https://github.com/MrCyjaneK/monero_c/releases/download/v0.18.4.0-RC9/release-bundle.zip
    git checkout 411e8a1cdb3f4c2812d83f28c335d2a4eb18bd29
    git reset --hard
    git submodule update --init --force --recursive
    ./apply_patches.sh monero
    ./apply_patches.sh wownero
    ./apply_patches.sh zano
else
    cd monero_c
fi

for coin in monero wownero zano;
do
    if [[ ! -f "$coin/.patch-applied" ]];
    then
        ./apply_patches.sh $coin
    fi
done
cd ..

echo "monero_c source prepared".
