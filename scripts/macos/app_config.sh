#!/bin/bash

CAKEWALLET="cakewallet"
DIR=`pwd`

if [ -z "$APP_MACOS_TYPE" ]; then
        echo "Please set APP_MACOS_TYPE"
        exit 1
fi

cd ../.. # go to root
cp -rf ./macos/Runner/InfoBase.plist ./macos/Runner/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier ${APP_MACOS_BUNDLE_ID}" ./macos/Runner/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${APP_MACOS_VERSION}" ./macos/Runner/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${APP_MACOS_BUILD_NUMBER}" ./macos/Runner/Info.plist

# Fill entitlements Bundle ID
cp -rf ./macos/Runner/DebugProfileBase.entitlements ./macos/Runner/DebugProfile.entitlements
cp -rf ./macos/Runner/ReleaseBase.entitlements ./macos/Runner/Release.entitlements
sed -i '' "s/\${BUNDLE_ID}/${APP_MACOS_BUNDLE_ID}/g" ./macos/Runner/DebugProfile.entitlements
sed -i '' "s/\${BUNDLE_ID}/${APP_MACOS_BUNDLE_ID}/g" ./macos/Runner/Release.entitlements
CONFIG_ARGS=""

case $APP_MACOS_TYPE in
        $CAKEWALLET)
		CONFIG_ARGS="--monero --bitcoin --ethereum --polygon --nano --bitcoinCash --decred";; #--haven
esac

cp -rf pubspec_description.yaml pubspec.yaml
flutter pub get
flutter pub run tool/generate_pubspec.dart
flutter pub get
flutter packages pub run tool/configure.dart $CONFIG_ARGS
cd $DIR