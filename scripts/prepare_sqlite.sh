#!/bin/bash

set -x -e

cd "$(dirname "$0")"

if [[ ! -d "sqlite/.git" ]];
then
    rm -rf sqlite
    git clone https://github.com/sqlite/sqlite.git sqlite
    cd sqlite
else
    cd sqlite
fi

git fetch -a
git checkout b09c88c14082339b66c7b7158d609a771e64ca69
git reset --hard

echo "sqlite source prepared".

./configure
make sqlite3.c