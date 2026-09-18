#!/bin/bash
set -x -e
cd "$(dirname "$0")"

HASH=0ce8e3cdc541f425d07cbecd8dd63202d6c8a23e

if [[ ! -d "torch_dart/.git" ]];
then
    rm -rf torch_dart
    git clone https://github.com/mrcyjanek/torch_dart
    cd torch_dart
else
    cd torch_dart
    git fetch -a
fi


git reset --hard
git checkout $HASH
git reset --hard

# recommended to uncomment during development
# sed -i.bak 's/go run . -cleanup/#go run . -cleanup/g' build.sh
