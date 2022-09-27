#!/bin/sh

. ./config.sh
echo ''$(git log -1 --pretty=format:"%H")' '$(date) >> build/git_commit_version.txt
VERSIONS_FILE=../../lib/git_versions.dart
EXAMPLE_VERSIONS_FILE=../../lib/git_versions_example.dart
if [ ! -f "$VERSIONS_FILE" ]; then
    cp $EXAMPLE_VERSIONS_FILE $VERSIONS_FILE
fi
COMMIT=$(git log -1 --pretty=format:"%H")
OS="LINUX"
sed -i "/\/\*${OS}_VERSION/c\\/\*${OS}_VERSION\*\/ const ${OS}_VERSION = \"$COMMIT\";" $VERSIONS_FILE
cd build
mkdir monero_build
mkdir wownero_build
MONERO_BUILD=$(pwd)/monero_build
WOWNERO_BUILD=$(pwd)/wownero_build

cd $MONERO_BUILD
cmake ../../cmakefiles/monero/${TYPES_OF_BUILD}
make -j$(nproc)
cp libcw_monero.so ../

cd $WOWNERO_BUILD
cmake ../../cmakefiles/wownero/${TYPES_OF_BUILD}
make -j$(nproc)
cp libcw_wownero.so ../

