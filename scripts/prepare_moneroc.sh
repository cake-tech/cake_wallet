#!/bin/bash

set -x -e

cd "$(dirname "$0")"

if [[ ! -d "monero_c" ]];
then
    git clone https://github.com/mrcyjanek/monero_c --branch master
    cd monero_c
    git checkout c3dd64bdee37d361a2c1252d127fb575936e43e6
    git reset --hard
    git submodule update --init --force --recursive
    ./apply_patches.sh monero
    ./apply_patches.sh wownero
    ./apply_patches.sh zano
    git submodule foreach --recursive 'git fetch --unshallow || echo "Not a shallow submodule"'
else
    cd monero_c
fi

for coin in monero wownero zano;
do
    if [[ ! -f "$coin/.patch-applied" ]];
    then
        ./apply_patches.sh $coin
        (cd $coin; git submodule foreach --recursive 'git fetch --unshallow || echo "Not a shallow submodule"'; cd ..)
    fi
done
cd ..

echo "monero_c source prepared".
