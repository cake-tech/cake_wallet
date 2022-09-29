#!/bin/sh

. ./config.sh
echo ''$(git log -1 --pretty=format:"%H")' '$(date) >> build/git_commit_version.txt
VERSIONS_FILE=../../lib/git_versions.dart
EXAMPLE_VERSIONS_FILE=../../lib/git_versions_example.dart
if [ ! -f "$VERSIONS_FILE" ]; then
    cp $EXAMPLE_VERSIONS_FILE $VERSIONS_FILE
fi
COMMIT=$(git log -1 --pretty=format:"%H")
OS="IOS"
sed -i '' "/\/\*${OS}_VERSION/c\\/\*${OS}_VERSION\*\/ const ${OS}_VERSION = \"$COMMIT\";" $VERSIONS_FILE
cd $EXTERNAL_IOS_LIB_DIR

LIBRANDOMX_PATH=${EXTERNAL_IOS_LIB_DIR}/monero/librandomx.a

if [ -f "$LIBRANDOMX_PATH" ]; then
    cp $LIBRANDOMX_PATH ./wownero
fi

libtool -static -o libboost.a ./libboost_*.a
libtool -static -o libwownero.a ./wownero/*.a
libtool -static -o libmonero.a ./monero/*.a


CW_WOWNERO_EXTERNAL_LIB=../../../../../cw_wownero/ios/External/ios/lib
CW_WOWNERO_EXTERNAL_INCLUDE=../../../../../cw_wownero/ios/External/ios/include
CW_MONERO_EXTERNAL_LIB=../../../../../cw_monero/ios/External/ios/lib
CW_MONERO_EXTERNAL_INCLUDE=../../../../../cw_monero/ios/External/ios/include

mkdir -p $CW_MONERO_EXTERNAL_INCLUDE
mkdir -p $CW_WOWNERO_EXTERNAL_INCLUDE
mkdir -p $CW_WOWNERO_EXTERNAL_LIB
mkdir -p $CW_MONERO_EXTERNAL_LIB



ln ./libboost.a ${CW_WOWNERO_EXTERNAL_LIB}/libboost.a
ln ./libcrypto.a ${CW_WOWNERO_EXTERNAL_LIB}/libcrypto.a
ln ./libssl.a ${CW_WOWNERO_EXTERNAL_LIB}/libssl.a
ln ./libsodium.a ${CW_WOWNERO_EXTERNAL_LIB}/libsodium.a
cp ./libwownero.a $CW_WOWNERO_EXTERNAL_LIB
cp ../include/wownero/* $CW_WOWNERO_EXTERNAL_INCLUDE
cp -r ../include/wownero_seed $CW_WOWNERO_EXTERNAL_INCLUDE

ln ./libboost.a ${CW_MONERO_EXTERNAL_LIB}/libboost.a
ln ./libcrypto.a ${CW_MONERO_EXTERNAL_LIB}/libcrypto.a
ln ./libssl.a ${CW_MONERO_EXTERNAL_LIB}/libssl.a
ln ./libsodium.a ${CW_MONERO_EXTERNAL_LIB}/libsodium.a
ln ./libunbound.a ${CW_MONERO_EXTERNAL_LIB}/libunbound.a
cp ./libmonero.a $CW_MONERO_EXTERNAL_LIB
cp ../include/monero/* $CW_MONERO_EXTERNAL_INCLUDE