#!/bin/bash

MONERO_COM="monero.com"
CAKEWALLET="cakewallet"
DIR=`pwd`

if [ -z "$APP_IOS_TYPE" ]; then
        echo "Please set APP_IOS_TYPE"
        exit 1
fi

cd ../.. # go to root
/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName ${APP_IOS_NAME}" ./ios/Runner/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier ${APP_IOS_BUNDLE_ID}" ./ios/Runner/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${APP_IOS_VERSION}" ./ios/Runner/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${APP_IOS_BUILD_NUMBER}" ./ios/Runner/Info.plist
CONFIG_ARGS=""

case $APP_IOS_TYPE in
        $MONERO_COM)
		CONFIG_ARGS="--monero"
		;;
        $CAKEWALLET)
		CONFIG_ARGS="--monero --bitcoin"
		;;
esac

flutter pub get
flutter pub run tool/generate_pubspec.dart
flutter packages pub run tool/configure.dart $CONFIG_ARGS
cd $DIR
$DIR/app_icon.sh
