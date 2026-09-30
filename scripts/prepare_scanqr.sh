#!/bin/bash

set -x -e

cd "$(dirname "$0")"

HASH=866f5755c1b6a020d1ec907e345b4b2c448c18a3

if [[ ! -d "scanqr_c_gozxing/.git" ]];
then
    rm -rf scanqr_c_gozxing
    git clone https://github.com/MrCyjaneK/scanqr_c_gozxing scanqr_c_gozxing
    cd scanqr_c_gozxing
else
    cd scanqr_c_gozxing
    git fetch -a
fi

git reset --hard
git checkout $HASH
git reset --hard

echo "scanqr_c_gozxing source prepared".
