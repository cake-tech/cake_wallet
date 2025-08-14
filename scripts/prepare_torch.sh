#!/bin/bash
set -x -e
cd "$(dirname "$0")"

# IMPORTANT: Make sure to update action 'Build Torch` in
# - .github/workflows/pr_test_build_android.yml 
# - .github/workflows/pr_test_build_linux.yml
HASH=b2d0fa5d1727f321226a1ccc63f2568d3aaa26f6

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
