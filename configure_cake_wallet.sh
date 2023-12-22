#!/bin/bash

IOS="ios"
ANDROID="android"
MACOS="macos"

PLATFORMS=($IOS $ANDROID $MACOS)
PLATFORM=$1

if ! [[ " ${PLATFORMS[*]} " =~ " ${PLATFORM} " ]]; then
    echo "specify platform: ./configure_cake_wallet.sh ios|android|macos"
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

source ./app_env.sh cakewallet
./app_config.sh
cd ../.. && flutter pub get
#flutter packages pub run tool/generate_localization.dart
./model_generator.sh
#cd macos && pod install
