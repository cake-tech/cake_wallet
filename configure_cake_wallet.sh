#!/bin/bash
set -x -e
IOS="ios"
ANDROID="android"
MACOS="macos"
LINUX="linux"

PLATFORMS=($IOS $ANDROID $MACOS $LINUX)
PLATFORM=$1

if ! [[ " ${PLATFORMS[*]} " =~ " ${PLATFORM} " ]]; then
    echo "specify platform: ./configure_cake_wallet.sh ios|android|macos|linux"
    exit 1
fi

if [ "$PLATFORM" == "$IOS" ]; then
    echo "Configuring for iOS"
    cd scripts/ios
fi

if [ "$PLATFORM" == "$MACOS" ]; then
    echo "Configuring for macOS"
    cd scripts/macos
fi

if [ "$PLATFORM" == "$ANDROID" ]; then
    echo "Configuring for Android"
    cd scripts/android
fi

if [ "$PLATFORM" == "$LINUX" ]; then
    echo "Configuring for linux"
    cd scripts/linux
fi

source ./app_env.sh cakewallet
./app_config.sh
cd ../.. && flutter pub get
dart run tool/generate_localization.dart
#./model_generator.sh
#cd macos && pod install
