#!/bin/sh

ICON_120_PATH=""
ICON_180_PATH=""
ICON_1024_PATH=""
DEST_DIR_PATH=`pwd`/../../ios/Runner/Assets.xcassets/AppIcon.appiconset

case $APP_IOS_TYPE in
	"monero.com")
	ICON_120_PATH=`pwd`/../../assets/images/monero.com_icon_120.png
	ICON_180_PATH=`pwd`/../../assets/images/monero.com_icon_180.png
	ICON_1024_PATH=`pwd`/../../assets/images/monero.com_icon_1024.png;;
	"cakewallet")
	ICON_120_PATH=`pwd`/../../assets/images/cakewallet_icon_120.png
    ICON_180_PATH=`pwd`/../../assets/images/cakewallet_icon_180.png
    ICON_1024_PATH=`pwd`/../../assets/images/cakewallet_icon_1024.png;;
    "haven")
	ICON_120_PATH=`pwd`/../../assets/images/cakewallet_icon_120.png
    ICON_180_PATH=`pwd`/../../assets/images/cakewallet_icon_180.png
    ICON_1024_PATH=`pwd`/../../assets/images/cakewallet_icon_1024.png;;
esac

rm $DEST_DIR_PATH/app_icon_120.png
rm $DEST_DIR_PATH/app_icon_180.png
rm $DEST_DIR_PATH/app_icon_1024.png
ln -s $ICON_120_PATH $DEST_DIR_PATH/app_icon_120.png
ln -s $ICON_180_PATH $DEST_DIR_PATH/app_icon_180.png
ln -s $ICON_1024_PATH $DEST_DIR_PATH/app_icon_1024.png