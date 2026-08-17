#!/bin/bash

set -x -e

cd "$(dirname "$0")"

if [[ ! -d "monero_c/.git" ]];
then
    rm -rf monero_c
    git clone https://github.com/mrcyjanek/monero_c --branch master monero_c
    cd monero_c
else
    cd monero_c
fi

git fetch -a
git checkout e62905e684a47551dbb041caf0762e00b588f67d
git reset --hard
git submodule update --init --force --recursive

for coin in monero wownero zano;
do
    if [[ ! -f "$coin/.patch-applied" ]];
    then
        ./apply_patches.sh $coin
    fi
done
cd ..

echo "monero_c source prepared".
