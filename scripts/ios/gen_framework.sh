#!/bin/sh
# Assume we are in scripts/ios

if [[ "$1" == "--simulator" ]];
then
    simulator=simulator
fi

IOS_DIR="$(pwd)/../../ios"


FRWK_DIR="${IOS_DIR}/MoneroWallet.framework"
cd $FRWK_DIR
lipo -create "../../scripts/monero_c/release/monero/aarch64-apple-ios${simulator}_libwallet2_api_c.dylib" -output MoneroWallet

FRWK_DIR="${IOS_DIR}/WowneroWallet.framework"
cd $FRWK_DIR
lipo -create "../../scripts/monero_c/release/wownero/aarch64-apple-ios${simulator}_libwallet2_api_c.dylib" -output WowneroWallet

FRWK_DIR="${IOS_DIR}/ZanoWallet.framework"
cd $FRWK_DIR
lipo -create "../../scripts/monero_c/release/zano/aarch64-apple-ios${simulator}_libwallet2_api_c.dylib" -output ZanoWallet

