#!/bin/bash
set -x -e
cd "$(dirname "$0")"

# IMPORTANT: Make sure to update action 'Build Torch` in
# - .github/workflows/pr_test_build_android.yml 
# - .github/workflows/pr_test_build_linux.yml
# https://github.com/MrCyjaneK/torch_dart/releases/download/4f987d4-1-ge071fcf/torch_dart-4f987d4-1-ge071fcf.tar.gz
HASH=e071fcfb454b0378933005853e29afd797a2022e

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
