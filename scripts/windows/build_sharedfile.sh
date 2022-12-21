#!/bin/bash
. ./config.sh

. ./copy_monero_deps.sh

echo ''$(git log -1 --pretty=format:"%H")' '$(date) >> build/git_commit_version.txt
VERSIONS_FILE=../../lib/git_versions.dart
EXAMPLE_VERSIONS_FILE=../../lib/git_versions_example.dart
if [ ! -f "$VERSIONS_FILE" ]; then
    cp $EXAMPLE_VERSIONS_FILE $VERSIONS_FILE
fi
COMMIT=$(git log -1 --pretty=format:"%H")
OS="WINDOWS"
sed -i "/\/\*${OS}_VERSION/c\\/\*${OS}_VERSION\*\/ const ${OS}_VERSION = \"$COMMIT\";" $VERSIONS_FILE

cd ${WORKDIR}
mkdir -p monero_build
mkdir -p wownero_build
MONERO_BUILD=${WORKDIR}/monero_build
WOWNERO_BUILD=${WORKDIR}/wownero_build

cd $MONERO_BUILD
x86_64-w64-mingw32.static-cmake ../../cmakefiles/monero/x86_64
make -j$(nproc)
cp libcw_monero.dll ../

cd $WOWNERO_BUILD
x86_64-w64-mingw32.static-cmake ../../cmakefiles/wownero/x86_64
make -j$(nproc)
cp libcw_wownero.dll ../
