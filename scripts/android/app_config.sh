#!/bin/bash

if [ -z "$APP_ANDROID_TYPE" ]; then
        echo "Please set APP_ANDROID_TYPE"
        exit 1
fi

"$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/use_boltz_client_mirror.sh" || exit 1

./app_properties.sh
./app_icon.sh
./pubspec_gen.sh
./manifest.sh true #force overwrite manifest
./inject_app_details.sh
