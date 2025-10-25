#!/bin/bash
set -x -e
cd "$(dirname "$0")"

# IMPORTANT: Make sure to update action 'Build Reown` in
# - .github/workflows/pr_test_build_android.yml 
# - .github/workflows/pr_test_build_linux.yml
# https://github.com/cake-tech/reown_flutter/releases/download/v0.0.4/reown_flutter-v0.0.4.tar.gz

HASH=8a6d79ef7a268c493eeba45feef9991eea119bbd

if [[ ! -d "reown_flutter/.git" ]];
then
    rm -rf reown_flutter
    git clone https://github.com/cake-tech/reown_flutter
    cd reown_flutter
else
    cd reown_flutter
    git fetch -a
fi

git reset --hard
git checkout $HASH
git reset --hard

./scripts/generate_all.sh