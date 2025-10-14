#!/bin/bash

git clone https://github.com/konstantinullrich/bitbox_flutter
cd bitbox_flutter
git checkout 5a6e6dd388ef64003f86094af80d5453518b601d
bash ./build_bindings.sh

FILE=api.aar
if [ -f "$FILE" ]; then
    echo "$FILE exists."
fi
