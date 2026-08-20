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

# NOTE: Make sure to update monero_c prebuilds link in workflow files
# https://github.com/MrCyjaneK/monero_c/releases/download/v0.18.4.6-RC2/release-bundle.zip
git fetch -a
git checkout d40974f1756032399c9aedbc8ececb5ebe3745c0
git reset --hard
sed -i.bak 's|codeberg.org/wownero|github.com/wownero-mirror|g' .gitmodules

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
