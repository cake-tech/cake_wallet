#!/bin/bash
set -x -e
cd "$(dirname "$0")"

# IMPORTANT: Make sure to update action 'Build Torch` in
# - .github/workflows/pr_test_build_android.yml 
# - .github/workflows/pr_test_build_linux.yml
# https://github.com/MrCyjaneK/torch_dart/releases/download/4f987d4-1-ge071fcf-1-gc282f09-1-g4c290aa-1-gabdf653/torch_dart-4f987d4-1-ge071fcf-1-gc282f09-1-g4c290aa-1-gabdf653.tar.gz

HASH=abdf653fc15b576f2a67597a1f9618345a297f45

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