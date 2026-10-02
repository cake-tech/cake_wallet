#!/bin/bash
set -x -e
cd "$(dirname "$0")"

HASH=3a35a32eee2ec29262c5275fc92079a7127f9ccc

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
