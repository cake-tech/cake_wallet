#!/bin/bash

APP_ANDROID_NAME=""
APP_ANDROID_VERSION=""
APP_ANDROID_BUILD_VERSION=""
APP_ANDROID_ID=""
APP_ANDROID_PACKAGE=""

MONERO_COM="monero.com"
CAKEWALLET="cakewallet"

TYPES=($MONERO_COM $CAKEWALLET)
APP_ANDROID_TYPE=$1

MONERO_COM_NAME="Monero.com"
MONERO_COM_VERSION="1.0.0"
MONERO_COM_BUILD_NUMBER=6
MONERO_COM_BUNDLE_ID="com.cakewallet.monero"
MONERO_COM_PACKAGE="com.monero.app"

CAKEWALLET_NAME="Cake Wallet"
CAKEWALLET_VERSION="4.3.4"
CAKEWALLET_BUILD_NUMBER=81
CAKEWALLET_BUNDLE_ID="com.cakewallet.cake_wallet"
CAKEWALLET_PACKAGE="com.cakewallet.cake_wallet"

if ! [[ " ${TYPES[*]} " =~ " ${APP_ANDROID_TYPE} " ]]; then
    echo "Wrong app type."
    exit 1
fi

case $APP_ANDROID_TYPE in
	$MONERO_COM)
		APP_ANDROID_NAME=$MONERO_COM_NAME
		APP_ANDROID_VERSION=$MONERO_COM_VERSION
		APP_ANDROID_BUILD_NUMBER=$MONERO_COM_BUILD_NUMBER
		APP_ANDROID_BUNDLE_ID=$MONERO_COM_BUNDLE_ID
		APP_ANDROID_PACKAGE=$MONERO_COM_PACKAGE
		;;
	$CAKEWALLET)
		APP_ANDROID_NAME=$CAKEWALLET_NAME
		APP_ANDROID_VERSION=$CAKEWALLET_VERSION
		APP_ANDROID_BUILD_NUMBER=$CAKEWALLET_BUILD_NUMBER
		APP_ANDROID_BUNDLE_ID=$CAKEWALLET_BUNDLE_ID
		APP_ANDROID_PACKAGE=$CAKEWALLET_PACKAGE
		;;
esac

export APP_ANDROID_TYPE
export APP_ANDROID_NAME
export APP_ANDROID_VERSION
export APP_ANDROID_BUILD_NUMBER
export APP_ANDROID_BUNDLE_ID
export APP_ANDROID_PACKAGE
