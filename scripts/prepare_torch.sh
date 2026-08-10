#!/bin/bash
set -x -e
cd "$(dirname "$0")"

# IMPORTANT: Make sure to update action 'Build Torch` in
# - .github/workflows/pr_test_build_android.yml
# - .github/workflows/pr_test_build_linux.yml
# https://github.com/MrCyjaneK/torch_dart/releases/download/v1.0.17/torch_dart-v1.0.17.tar.gz

HASH=79e5361f43b8aadd340d2900009cf09590b2a0bb

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
