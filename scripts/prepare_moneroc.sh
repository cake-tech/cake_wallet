#!/bin/bash

set -x -e

cd "$(dirname "$0")"

if [[ ! -d "monero_c/.git" ]];
then
    git clone https://github.com/mrcyjanek/monero_c --branch master monero_c
    cd monero_c
    git checkout b335585a7fb94b315eb52bd88f2da6d3489fa508
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
