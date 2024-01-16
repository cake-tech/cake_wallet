#!/bin/sh

ICON_16_PATH=""
ICON_32_PATH=""
ICON_64_PATH=""
ICON_128_PATH=""
ICON_256_PATH=""
ICON_1024_PATH=""
DEST_DIR_PATH=`pwd`/../../macos/Runner/Assets.xcassets/AppIcon.appiconset

case $APP_MACOS_TYPE in
	"monero.com")
	ICON_16_PATH=`pwd`/../../assets/images/macos_icons/monero_macos_icons/monero_macos_16.png
	ICON_32_PATH=`pwd`/../../assets/images/macos_icons/monero_macos_icons/monero_macos_32.png
	ICON_64_PATH=`pwd`/../../assets/images/macos_icons/monero_macos_icons/monero_macos_64.png
	ICON_128_PATH=`pwd`/../../assets/images/macos_icons/monero_macos_icons/monero_macos_128.png
	ICON_256_PATH=`pwd`/../../assets/images/macos_icons/monero_macos_icons/monero_macos_256.png
	ICON_512_PATH=`pwd`/../../assets/images/macos_icons/monero_macos_icons/monero_macos_512.png
	ICON_1024_PATH=`pwd`/../../assets/images/macos_icons/monero_macos_icons/monero_macos_1024.png;;
	"cakewallet")
	ICON_16_PATH=`pwd`/../../assets/images/macos_icons/cakewallet_macos_icons/cakewallet_macos_16.png
	ICON_32_PATH=`pwd`/../../assets/images/macos_icons/cakewallet_macos_icons/cakewallet_macos_32.png
	ICON_64_PATH=`pwd`/../../assets/images/macos_icons/cakewallet_macos_icons/cakewallet_macos_64.png
	ICON_128_PATH=`pwd`/../../assets/images/macos_icons/cakewallet_macos_icons/cakewallet_macos_128.png
	ICON_256_PATH=`pwd`/../../assets/images/macos_icons/cakewallet_macos_icons/cakewallet_macos_256.png
	ICON_512_PATH=`pwd`/../../assets/images/macos_icons/cakewallet_macos_icons/cakewallet_macos_512.png
	ICON_1024_PATH=`pwd`/../../assets/images/macos_icons/cakewallet_macos_icons/cakewallet_macos_1024.png;;
esac

rm $DEST_DIR_PATH/app_icon_16.png
rm $DEST_DIR_PATH/app_icon_32.png
rm $DEST_DIR_PATH/app_icon_64.png
rm $DEST_DIR_PATH/app_icon_128.png
rm $DEST_DIR_PATH/app_icon_256.png
rm $DEST_DIR_PATH/app_icon_512.png
rm $DEST_DIR_PATH/app_icon_1024.png

ln -s $ICON_16_PATH $DEST_DIR_PATH/app_icon_16.png
ln -s $ICON_32_PATH $DEST_DIR_PATH/app_icon_32.png
ln -s $ICON_64_PATH $DEST_DIR_PATH/app_icon_64.png
ln -s $ICON_128_PATH $DEST_DIR_PATH/app_icon_128.png
ln -s $ICON_256_PATH $DEST_DIR_PATH/app_icon_256.png
ln -s $ICON_512_PATH $DEST_DIR_PATH/app_icon_512.png
ln -s $ICON_1024_PATH $DEST_DIR_PATH/app_icon_1024.png