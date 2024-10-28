#!/usr/bin/env fish

set APP_ANDROID_NAME ""
set APP_ANDROID_VERSION ""
set APP_ANDROID_BUILD_VERSION ""
set APP_ANDROID_ID ""
set APP_ANDROID_PACKAGE ""
set APP_ANDROID_SCHEME ""

set MONERO_COM "monero.com"
set CAKEWALLET cakewallet
set HAVEN haven

set -l TYPES $MONERO_COM $CAKEWALLET $HAVEN
set APP_ANDROID_TYPE $argv[1]

set MONERO_COM_NAME "Monero.com"
set MONERO_COM_VERSION "1.17.0"
set MONERO_COM_BUILD_NUMBER 103
set MONERO_COM_BUNDLE_ID "com.monero.app"
set MONERO_COM_PACKAGE "com.monero.app"
set MONERO_COM_SCHEME "monero.com"

set CAKEWALLET_NAME "Cake Wallet"
set CAKEWALLET_VERSION "4.20.0"
set CAKEWALLET_BUILD_NUMBER 232
set CAKEWALLET_BUNDLE_ID "com.cakewallet.cake_wallet"
set CAKEWALLET_PACKAGE "com.cakewallet.cake_wallet"
set CAKEWALLET_SCHEME cakewallet

set HAVEN_NAME Haven
set HAVEN_VERSION "1.0.0"
set HAVEN_BUILD_NUMBER 1
set HAVEN_BUNDLE_ID "com.cakewallet.haven"
set HAVEN_PACKAGE "com.cakewallet.haven"

if not contains $APP_ANDROID_TYPE $TYPES
    echo "Wrong app type."
    return 1
    exit 1
end

switch $APP_ANDROID_TYPE
    case $MONERO_COM
        set APP_ANDROID_NAME $MONERO_COM_NAME
        set APP_ANDROID_VERSION $MONERO_COM_VERSION
        set APP_ANDROID_BUILD_NUMBER $MONERO_COM_BUILD_NUMBER
        set APP_ANDROID_BUNDLE_ID $MONERO_COM_BUNDLE_ID
        set APP_ANDROID_PACKAGE $MONERO_COM_PACKAGE
        set APP_ANDROID_SCHEME $MONERO_COM_SCHEME

    case $CAKEWALLET
        set APP_ANDROID_NAME $CAKEWALLET_NAME
        set APP_ANDROID_VERSION $CAKEWALLET_VERSION
        set APP_ANDROID_BUILD_NUMBER $CAKEWALLET_BUILD_NUMBER
        set APP_ANDROID_BUNDLE_ID $CAKEWALLET_BUNDLE_ID
        set APP_ANDROID_PACKAGE $CAKEWALLET_PACKAGE
        set APP_ANDROID_SCHEME $CAKEWALLET_SCHEME

    case $HAVEN
        set APP_ANDROID_NAME $HAVEN_NAME
        set APP_ANDROID_VERSION $HAVEN_VERSION
        set APP_ANDROID_BUILD_NUMBER $HAVEN_BUILD_NUMBER
        set APP_ANDROID_BUNDLE_ID $HAVEN_BUNDLE_ID
        set APP_ANDROID_PACKAGE $HAVEN_PACKAGE

end

export APP_ANDROID_TYPE
export APP_ANDROID_NAME
export APP_ANDROID_VERSION
export APP_ANDROID_BUILD_NUMBER
export APP_ANDROID_BUNDLE_ID
export APP_ANDROID_PACKAGE
export APP_ANDROID_SCHEME
export APP_ANDROID_BUNDLE_ID
export APP_ANDROID_PACKAGE
export APP_ANDROID_SCHEME
