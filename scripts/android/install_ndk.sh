#!/bin/sh

. ./config.sh
ANDROID_NDK_SHA256="8381c440fe61fcbb01e209211ac01b519cd6adf51ab1c2281d5daad6ca4c8c8c"

curl https://dl.google.com/android/repository/android-ndk-r20b-linux-x86_64.zip -o ${ANDROID_NDK_ZIP}
echo $ANDROID_NDK_SHA256 $ANDROID_NDK_ZIP | sha256sum -c || exit 1
unzip /opt/android/android-ndk-r20b.zip -d $WORKDIR
