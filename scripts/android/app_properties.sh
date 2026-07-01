#!/bin/bash

APP_PROPERTIES_PATH=./../../android/app.properties

if [ -z "$APP_ANDROID_TYPE" ]; then
        echo "Please set APP_ANDROID_TYPE"
        exit 1
fi

touch $APP_PROPERTIES_PATH

echo -e "id=${APP_ANDROID_BUNDLE_ID}\nname=${APP_ANDROID_NAME}" > $APP_PROPERTIES_PATH