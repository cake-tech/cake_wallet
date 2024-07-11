#!/bin/bash

cd ../..

if [ "$1" = true ]; then
    cp -rf ./android/app/src/main/AndroidManifestBase.xml ./android/app/src/main/AndroidManifest.xml
else
    cp -n ./android/app/src/main/AndroidManifestBase.xml ./android/app/src/main/AndroidManifest.xml
fi
cd scripts/android
