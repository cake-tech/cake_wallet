#!/bin/bash
set -x -e

if [[ ! -d "bitbox_flutter" ]];
then
    git clone https://github.com/konstantinullrich/bitbox_flutter
fi

cd bitbox_flutter
git fetch -a
git reset --hard
git checkout 5a6e6dd388ef64003f86094af80d5453518b601d
git reset --hard

bash ./build_bindings.sh --dont-install

FILE=api.aar
if [ -f "$FILE" ]; then
    echo "$FILE exists."
fi
