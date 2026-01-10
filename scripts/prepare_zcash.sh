#!/bin/bash
set -x -e
cd "$(dirname "$0")"

HASH=f4f64ec71a0c22fc810409917ff06487341b783c

if [[ ! -d "zcash_lib/.git" ]];
then
    rm -rf zcash_lib
    git clone https://github.com/MrCyjaneK/zwallet.git zcash_lib
    cd zcash_lib
else
    cd zcash_lib
    git fetch -a
fi


git reset --hard
git checkout $HASH
git reset --hard
git submodule update --init --force --recursive
