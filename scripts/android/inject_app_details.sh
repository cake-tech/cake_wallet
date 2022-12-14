#!/bin/bash

if [ -z "$APP_ANDROID_TYPE" ]; then
        echo "Please set APP_ANDROID_TYPE"
        exit 1
fi

cd ../..
sed -i "0,/version:/{s/version:.*/version: ${APP_ANDROID_VERSION}+${APP_ANDROID_BUILD_NUMBER}/}" ./pubspec.yaml 
sed -i "0,/version:/{s/__APP_PACKAGE__/${APP_ANDROID_PACKAGE}/}" ./android/app/src/main/AndroidManifest.xml
cd scripts/android