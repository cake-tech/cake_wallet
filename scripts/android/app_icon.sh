#!/bin/sh
APP_LOGO=""
APP_LOGO_DEST_PATH=`pwd`/../../assets/images/app_logo.png
ASSETS_DIR=`pwd`/../../assets
ANDROID_ICON_DIR=`pwd`/../../android/app/src/main/res/drawable
MONERO_COM_PATH=$ASSETS_DIR/images/monero.com_android_icon.png
MONEROCOM_ICON_SET_PATH=$ASSETS_DIR/images/monerocom_android_icon
CAKEWALLET_PATH=$ASSETS_DIR/images/cakewallet_android_icon.png
CAKEWALLET_ICON_SET_PATH=$ASSETS_DIR/images/cakewallet_android_icon
ANDROID_ICON=""
ANDROID_ICON_DEST_PATH=$ANDROID_ICON_DIR/ic_launcher.png
ANDROID_ICON_SET=""
ANDROID_ICON_SET_DEST_PATH=`pwd`/../../android/app/src/main/res

case $APP_ANDROID_TYPE in
	"monero.com")
		APP_LOGO=$ASSETS_DIR/images/monero.com_logo.png
		ANDROID_ICON=$MONERO_COM_PATH
		ANDROID_ICON_SET=$MONEROCOM_ICON_SET_PATH
	;;
	"cakewallet")
    	APP_LOGO=$ASSETS_DIR/images/cakewallet_logo.png
    	ANDROID_ICON=$CAKEWALLET_PATH
    	ANDROID_ICON_SET=$CAKEWALLET_ICON_SET_PATH
    	;;
    "haven")
    	APP_LOGO=$ASSETS_DIR/images/cakewallet_logo.png
    	ANDROID_ICON=$CAKEWALLET_PATH
    	ANDROID_ICON_SET=$CAKEWALLET_ICON_SET_PATH
    	;;
esac

rm $APP_LOGO_DEST_PATH
rm $ANDROID_ICON_DEST_PATH
ln -s $APP_LOGO $APP_LOGO_DEST_PATH
ln -s $ANDROID_ICON $ANDROID_ICON_DEST_PATH
cp -a $ANDROID_ICON_SET/. $ANDROID_ICON_SET_DEST_PATH/
