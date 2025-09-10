#!/bin/bash
set -x -e
cd "$(dirname "$0")"

# IMPORTANT: Make sure to update action 'Build Torch` in
# - .github/workflows/pr_test_build_android.yml 
# - .github/workflows/pr_test_build_linux.yml
# https://github.com/MrCyjaneK/torch_dart/releases/download/v1.0.4/torch_dart-v1.0.4.tar.gz

HASH=8d22697df9d1e43ac98dd55087190bae17d32c05

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