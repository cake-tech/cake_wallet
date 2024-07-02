#!/bin/bash

ANDROID_SCRIPTS_DIR=`pwd`/android
if [ ! -d $ANDROID_SCRIPTS_DIR ]; then
    echo "no android scripts directory found at ${ANDROID_SCRIPTS_DIR}"
    exit 0
fi

cd $ANDROID_SCRIPTS_DIR
./manifest.sh
