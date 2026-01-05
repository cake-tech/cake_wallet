#!/bin/bash
set -x -e
cd "$(dirname "$0")"

HASH=0f141f5cfb41297a3181050c435f124ac128642b

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
