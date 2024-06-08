#!/bin/bash

if [ -z "$APP_ANDROID_TYPE" ]; then
        echo "Please set APP_ANDROID_TYPE"
        exit 1
fi

cd ../..

# the sed command is slightly different for MacOS than linux:
# https://stackoverflow.com/questions/4247068/sed-command-with-i-option-failing-on-mac-but-works-on-linux
# the sed command is slightly different for MacOS than linux:
# https://stackoverflow.com/questions/4247068/sed-command-with-i-option-failing-on-mac-but-works-on-linux
if [ "$(uname)" == "Darwin" ]; then
    sed -i '' "1,/version:.*/s/version:.*/version: ${APP_ANDROID_VERSION}+${APP_ANDROID_BUILD_NUMBER}/" ./pubspec.yaml
    sed -i '' "1,/__APP_PACKAGE__/s/__APP_PACKAGE__/${APP_ANDROID_PACKAGE}/" ./android/app/src/main/AndroidManifest.xml
    sed -i '' "1,/__APP_SCHEME__/s/__APP_SCHEME__/${APP_ANDROID_SCHEME}/" ./android/app/src/main/AndroidManifest.xml
    sed -i '' "1,/__versionCode__/s/__versionCode__/${APP_ANDROID_BUILD_NUMBER}/" ./android/app/src/main/AndroidManifest.xml
    sed -i '' "1,/__versionName__/s/__versionName__/${APP_ANDROID_VERSION}/" ./android/app/src/main/AndroidManifest.xml
else
    sed -i "0,/version:/{s/version:.*/version: ${APP_ANDROID_VERSION}+${APP_ANDROID_BUILD_NUMBER}/}" ./pubspec.yaml
    sed -i "0,/version:/{s/__APP_PACKAGE__/${APP_ANDROID_PACKAGE}/}" ./android/app/src/main/AndroidManifest.xml
    sed -i "0,/__APP_SCHEME__/s/__APP_SCHEME__/${APP_ANDROID_SCHEME}/" ./android/app/src/main/AndroidManifest.xml
    sed -i "0,/version:/{s/__versionCode__/${APP_ANDROID_BUILD_NUMBER}/}" ./android/app/src/main/AndroidManifest.xml
    sed -i "0,/version:/{s/__versionName__/${APP_ANDROID_VERSION}/}" ./android/app/src/main/AndroidManifest.xml
fi

cd scripts/android