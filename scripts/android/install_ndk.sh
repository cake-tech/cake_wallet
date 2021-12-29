#!/bin/sh

. ./config.sh
ANDROID_NDK_SHA256="3f541adbd0330a9205ba12697f6d04ec90752c53d6b622101a2a8a856e816589"

curl https://dl.google.com/android/repository/android-ndk-r17c-linux-x86_64.zip -o ${ANDROID_NDK_ZIP}
echo $ANDROID_NDK_SHA256 $ANDROID_NDK_ZIP | sha256sum -c || exit 1
unzip /opt/android/android-ndk-r17c.zip -d $WORKDIR
