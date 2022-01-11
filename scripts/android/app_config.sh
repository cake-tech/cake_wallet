#!/bin/bash

if [ -z "$APP_ANDROID_TYPE" ]; then
        echo "Please set APP_ANDROID_TYPE"
        exit 1
fi

sed -i "0,/version:/{s/version:.*/version: ${APP_ANDROID_VERSION}+${APP_ANDROID_BUILD_NUMBER}/}" ./../../pubspec.yaml 
sed -i "0,/version:/{s/__APP_PACKAGE__/${APP_ANDROID_PACKAGE}/}" ./../../android/app/src/main/AndroidManifest.xml
./app_icon.sh

CONFIG_ARGS=""

case $APP_ANDROID_TYPE in
        $MONERO_COM)
                CONFIG_ARGS="--monero"
                ;;
        $CAKEWALLET)
                CONFIG_ARGS="--monero --bitcoin"
                ;;
esac

cd ../..
flutter pub get
flutter pub run tool/generate_pubspec.dart
flutter packages pub run tool/configure.dart $CONFIG_ARGS
