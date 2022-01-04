#!/bin/sh
ICON_PATH=""
DEST_PATH=`pwd`/../../assets/images/app_logo.png

case $APP_ANDROID_TYPE in
	"monero.com")
	ICON_PATH=`pwd`/../../assets/images/monero.com_logo.png;;
	"cakewallet")
        ICON_PATH=`pwd`/../../assets/images/cakewallet_logo.png;;
esac

rm $DEST_PATH
ln -s $ICON_PATH $DEST_PATH


