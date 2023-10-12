#!/bin/bash

if [ -z "$APP_ANDROID_TYPE" ]; then
        echo "Please set APP_ANDROID_TYPE"
        exit 1
fi

./app_properties.sh
./app_icon.sh
./pubspec_gen.sh
./manifest.sh
./inject_app_details.sh
