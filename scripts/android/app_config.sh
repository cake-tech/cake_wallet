#!/bin/bash

if [ -z "$APP_ANDROID_TYPE" ]; then
        echo "Please set APP_ANDROID_TYPE"
        exit 1
fi

sed -i '0,/version:/{s/version:.*/version: ${APP_ANDROID_VERSION}+${APP_ANDROID_BUILD_NUMBER}/}' ./../../pubspec.yaml 
