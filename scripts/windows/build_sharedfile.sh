#!/bin/bash

. ./config.sh
echo ''$(git log -1 --pretty=format:"%H")' '$(date) >> build/git_commit_version.txt
VERSIONS_FILE=../../lib/git_versions.dart
EXAMPLE_VERSIONS_FILE=../../lib/git_versions_example.dart
if [ ! -f "$VERSIONS_FILE" ]; then
    cp $EXAMPLE_VERSIONS_FILE $VERSIONS_FILE
fi
COMMIT=$(git log -1 --pretty=format:"%H")
OS="LINUX" # TODO detect environment variable
sed -i "/\/\*${OS}_VERSION/c\\/\*${OS}_VERSION\*\/ const ${OS}_VERSION = \"$COMMIT\";" $VERSIONS_FILE
cd build
mkdir monero_build
mkdir wownero_build
MONERO_BUILD=$(pwd)/monero_build
WOWNERO_BUILD=$(pwd)/wownero_build

cd $MONERO_BUILD
x86_64-w64-mingw32.static-cmake ../../cmakefiles/monero/x86_64
make -j$(nproc)
cp libcw_monero.so ../

cd $WOWNERO_BUILD
x86_64-w64-mingw32.static-cmake ../../cmakefiles/wownero/x86_64
make -j$(nproc)
cp libcw_wownero.so ../
