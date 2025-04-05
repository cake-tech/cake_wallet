#!/bin/sh

ICON_2x_PATH=""
ICON_2x_ipad_PATH=""
ICON_3x_PATH=""
ICON_20_2x_PATH=""
ICON_20_2x_ipad_PATH=""
ICON_20_3x_PATH=""
ICON_20_ipad_PATH=""
ICON_29_PATH=""
ICON_29_2x_PATH=""
ICON_29_2x_ipad_PATH=""
ICON_29_3x_PATH=""
ICON_29_3x_ipad_PATH=""
ICON_29_ipad_PATH=""
ICON_40_2x_PATH=""
ICON_40_2x_ipad_PATH=""
ICON_40_3x_PATH=""
ICON_40_ipad_PATH=""
ICON_60_2x_PATH=""
ICON_60_3x_PATH=""
ICON_83_2x_ipad_PATH=""
ICON_marketing_PATH=""
ICON_ipad_PATH=""

ICON_DIRECTORY=""

DEST_DIR_PATH=`pwd`/../../ios/Runner/Assets.xcassets/AppIcon.appiconset

case $APP_IOS_TYPE in
	"monero.com")
    ICON_DIRECTORY=monero_ios_icons;;
	"cakewallet")
    ICON_DIRECTORY=cakewallet_ios_icons;;
esac

ICON_2x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/AppIcon@2x.png
ICON_2x_ipad_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/AppIcon@2x~ipad.png
ICON_3x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/AppIcon@3x.png
ICON_20_2x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/AppIcon-20@2x.png
ICON_20_2x_ipad_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/AppIcon-20@2x~ipad.png
ICON_20_3x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/AppIcon-20@3x.png
ICON_20_ipad_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/AppIcon-20~ipad.png
ICON_29_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/AppIcon-29.png
ICON_29_2x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/AppIcon-29@2x.png
ICON_29_2x_ipad_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/AppIcon-29@2x~ipad.png
ICON_29_3x_ipad_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/AppIcon-29@3x.png
ICON_29_ipad_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/AppIcon-29~ipad.png
ICON_40_2x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/AppIcon-40@2x.png
ICON_40_2x_ipad_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/AppIcon-40@2x~ipad.png
ICON_40_3x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/AppIcon-40@3x.png
ICON_40_ipad_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/AppIcon-40~ipad.png
ICON_60_2x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/AppIcon-60@2x~car.png
ICON_60_3x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/AppIcon-60@3x~car.png
ICON_83_2x_ipad_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/AppIcon-83.5@2x~ipad.png
ICON_marketing_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/AppIcon~ios-marketing.png
ICON_ipad_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/AppIcon~ipad.png

rm $DEST_DIR_PATH/AppIcon@2x.png
rm $DEST_DIR_PATH/AppIcon@2x~ipad.png
rm $DEST_DIR_PATH/AppIcon@3x.png
rm $DEST_DIR_PATH/AppIcon-20@2x.png
rm $DEST_DIR_PATH/AppIcon-20@2x~ipad.png
rm $DEST_DIR_PATH/AppIcon-20@3x.png
rm $DEST_DIR_PATH/AppIcon-20~ipad.png
rm $DEST_DIR_PATH/AppIcon-29.png
rm $DEST_DIR_PATH/AppIcon-29@2x.png
rm $DEST_DIR_PATH/AppIcon-29@2x~ipad.png
rm $DEST_DIR_PATH/AppIcon-29@3x.png
rm $DEST_DIR_PATH/AppIcon-29~ipad.png
rm $DEST_DIR_PATH/AppIcon-40@2x.png
rm $DEST_DIR_PATH/AppIcon-40@2x~ipad.png
rm $DEST_DIR_PATH/AppIcon-40@3x.png
rm $DEST_DIR_PATH/AppIcon-40~ipad.png
rm $DEST_DIR_PATH/AppIcon-60@2x~car.png
rm $DEST_DIR_PATH/AppIcon-60@3x~car.png
rm $DEST_DIR_PATH/AppIcon-83.5@2x~ipad.png
rm $DEST_DIR_PATH/AppIcon~ios-marketing.png
rm $DEST_DIR_PATH/AppIcon~ipad.png

ln -s $ICON_2x_PATH $DEST_DIR_PATH/AppIcon@2x.png
ln -s $ICON_2x_ipad_PATH $DEST_DIR_PATH/AppIcon@2x~ipad.png
ln -s $ICON_3x_PATH $DEST_DIR_PATH/AppIcon@3x.png
ln -s $ICON_20_2x_PATH $DEST_DIR_PATH/AppIcon-20@2x.png
ln -s $ICON_20_2x_ipad_PATH $DEST_DIR_PATH/AppIcon-20@2x~ipad.png
ln -s $ICON_20_3x_PATH $DEST_DIR_PATH/AppIcon-20@3x.png
ln -s $ICON_20_ipad_PATH $DEST_DIR_PATH/AppIcon-20~ipad.png
ln -s $ICON_29_PATH $DEST_DIR_PATH/AppIcon-29.png
ln -s $ICON_29_2x_PATH $DEST_DIR_PATH/AppIcon-29@2x.png
ln -s $ICON_29_2x_ipad_PATH $DEST_DIR_PATH/AppIcon-29@2x~ipad.png
ln -s $ICON_29_3x_ipad_PATH $DEST_DIR_PATH/AppIcon-29@3x.png
ln -s $ICON_29_ipad_PATH $DEST_DIR_PATH/AppIcon-29~ipad.png
ln -s $ICON_40_2x_PATH $DEST_DIR_PATH/AppIcon-40@2x.png
ln -s $ICON_40_2x_ipad_PATH $DEST_DIR_PATH/AppIcon-40@2x~ipad.png
ln -s $ICON_40_3x_PATH $DEST_DIR_PATH/AppIcon-40@3x.png
ln -s $ICON_40_ipad_PATH $DEST_DIR_PATH/AppIcon-40~ipad.png
ln -s $ICON_60_2x_PATH $DEST_DIR_PATH/AppIcon-60@2x~car.png
ln -s $ICON_60_3x_PATH $DEST_DIR_PATH/AppIcon-60@3x~car.png
ln -s $ICON_83_2x_ipad_PATH $DEST_DIR_PATH/AppIcon-83.5@2x~ipad.png
ln -s $ICON_marketing_PATH $DEST_DIR_PATH/AppIcon~ios-marketing.png
ln -s $ICON_ipad_PATH $DEST_DIR_PATH/AppIcon~ipad.png
