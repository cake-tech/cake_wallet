#!/bin/sh

CONTENTS_JSON_PATH=""

ICON_20_2x_PATH=""
ICON_20_3x_PATH=""
ICON_29_2x_PATH=""
ICON_29_3x_PATH=""
ICON_38_2x_PATH=""
ICON_38_3x_PATH=""
ICON_40_2x_PATH=""
ICON_40_3x_PATH=""
ICON_60_2x_PATH=""
ICON_60_3x_PATH=""
ICON_64_2x_PATH=""
ICON_64_3x_PATH=""
ICON_68_2x_PATH=""
ICON_76_2x_PATH=""
ICON_83_5_2x_PATH=""
ICON_1024_1x_PATH=""

ICON_DARK_20_2x_PATH=""
ICON_DARK_20_3x_PATH=""
ICON_DARK_29_2x_PATH=""
ICON_DARK_29_3x_PATH=""
ICON_DARK_38_2x_PATH=""
ICON_DARK_38_3x_PATH=""
ICON_DARK_40_2x_PATH=""
ICON_DARK_40_3x_PATH=""
ICON_DARK_60_2x_PATH=""
ICON_DARK_60_3x_PATH=""
ICON_DARK_64_2x_PATH=""
ICON_DARK_64_3x_PATH=""
ICON_DARK_68_2x_PATH=""
ICON_DARK_76_2x_PATH=""
ICON_DARK_83_5_2x_PATH=""
ICON_DARK_1024_1x_PATH=""

ICON_TINTED_20_2x_PATH=""
ICON_TINTED_20_3x_PATH=""
ICON_TINTED_29_2x_PATH=""
ICON_TINTED_29_3x_PATH=""
ICON_TINTED_38_2x_PATH=""
ICON_TINTED_38_3x_PATH=""
ICON_TINTED_40_2x_PATH=""
ICON_TINTED_40_3x_PATH=""
ICON_TINTED_60_2x_PATH=""
ICON_TINTED_60_3x_PATH=""
ICON_TINTED_64_2x_PATH=""
ICON_TINTED_64_3x_PATH=""
ICON_TINTED_68_2x_PATH=""
ICON_TINTED_76_2x_PATH=""
ICON_TINTED_83_5_2x_PATH=""
ICON_TINTED_1024_1x_PATH=""

DEST_DIR_PATH=`pwd`/../../ios/Runner/Assets.xcassets/AppIcon.appiconset

case $APP_IOS_TYPE in
	"monero.com")
    ICON_DIRECTORY=monero_ios_icons;;
	"cakewallet")
    ICON_DIRECTORY=cakewallet_ios_icons;;
esac

CONTENTS_JSON_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/Contents.json

ICON_20_2x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/Icon-App-20x20@2x.png
ICON_20_3x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/Icon-App-20x20@3x.png
ICON_29_2x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/Icon-App-29x29@2x.png
ICON_29_3x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/Icon-App-29x29@3x.png
ICON_38_2x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/Icon-App-38x38@2x.png
ICON_38_3x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/Icon-App-38x38@3x.png
ICON_40_2x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/Icon-App-40x40@2x.png
ICON_40_3x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/Icon-App-40x40@3x.png
ICON_60_2x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/Icon-App-60x60@2x.png
ICON_60_3x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/Icon-App-60x60@3x.png
ICON_64_2x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/Icon-App-64x64@2x.png
ICON_64_3x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/Icon-App-64x64@3x.png
ICON_68_2x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/Icon-App-68x68@2x.png
ICON_76_2x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/Icon-App-76x76@2x.png
ICON_83_5_2x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/Icon-App-83.5x83.5@2x.png
ICON_1024_1x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/Icon-App-1024x1024@1x.png

ICON_DARK_20_2x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/Icon-App-Dark-20x20@2x.png
ICON_DARK_20_3x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/Icon-App-Dark-20x20@3x.png
ICON_DARK_29_2x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/Icon-App-Dark-29x29@2x.png
ICON_DARK_29_3x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/Icon-App-Dark-29x29@3x.png
ICON_DARK_38_2x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/Icon-App-Dark-38x38@2x.png
ICON_DARK_38_3x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/Icon-App-Dark-38x38@3x.png
ICON_DARK_40_2x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/Icon-App-Dark-40x40@2x.png
ICON_DARK_40_3x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/Icon-App-Dark-40x40@3x.png
ICON_DARK_60_2x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/Icon-App-Dark-60x60@2x.png
ICON_DARK_60_3x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/Icon-App-Dark-60x60@3x.png
ICON_DARK_64_2x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/Icon-App-Dark-64x64@2x.png
ICON_DARK_64_3x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/Icon-App-Dark-64x64@3x.png
ICON_DARK_68_2x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/Icon-App-Dark-68x68@2x.png
ICON_DARK_76_2x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/Icon-App-Dark-76x76@2x.png
ICON_DARK_83_5_2x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/Icon-App-Dark-83.5x83.5@2x.png
ICON_DARK_1024_1x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/Icon-App-Dark-1024x1024@1x.png

ICON_TINTED_20_2x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/Icon-App-Tinted-20x20@2x.png
ICON_TINTED_20_3x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/Icon-App-Tinted-20x20@3x.png
ICON_TINTED_29_2x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/Icon-App-Tinted-29x29@2x.png
ICON_TINTED_29_3x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/Icon-App-Tinted-29x29@3x.png
ICON_TINTED_38_2x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/Icon-App-Tinted-38x38@2x.png
ICON_TINTED_38_3x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/Icon-App-Tinted-38x38@3x.png
ICON_TINTED_40_2x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/Icon-App-Tinted-40x40@2x.png
ICON_TINTED_40_3x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/Icon-App-Tinted-40x40@3x.png
ICON_TINTED_60_2x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/Icon-App-Tinted-60x60@2x.png
ICON_TINTED_60_3x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/Icon-App-Tinted-60x60@3x.png
ICON_TINTED_64_2x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/Icon-App-Tinted-64x64@2x.png
ICON_TINTED_64_3x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/Icon-App-Tinted-64x64@3x.png
ICON_TINTED_68_2x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/Icon-App-Tinted-68x68@2x.png
ICON_TINTED_76_2x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/Icon-App-Tinted-76x76@2x.png
ICON_TINTED_83_5_2x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/Icon-App-Tinted-83.5x83.5@2x.png
ICON_TINTED_1024_1x_PATH=`pwd`/../../assets/images/ios_icons/$ICON_DIRECTORY/Icon-App-Tinted-1024x1024@1x.png

rm $DEST_DIR_PATH/Contents.json

rm $DEST_DIR_PATH/Icon-App-20x20@2x.png
rm $DEST_DIR_PATH/Icon-App-20x20@3x.png
rm $DEST_DIR_PATH/Icon-App-29x29@2x.png
rm $DEST_DIR_PATH/Icon-App-29x29@3x.png
rm $DEST_DIR_PATH/Icon-App-38x38@2x.png
rm $DEST_DIR_PATH/Icon-App-38x38@3x.png
rm $DEST_DIR_PATH/Icon-App-40x40@2x.png
rm $DEST_DIR_PATH/Icon-App-40x40@3x.png
rm $DEST_DIR_PATH/Icon-App-60x60@2x.png
rm $DEST_DIR_PATH/Icon-App-60x60@3x.png
rm $DEST_DIR_PATH/Icon-App-64x64@2x.png
rm $DEST_DIR_PATH/Icon-App-64x64@3x.png
rm $DEST_DIR_PATH/Icon-App-68x68@2x.png
rm $DEST_DIR_PATH/Icon-App-76x76@2x.png
rm $DEST_DIR_PATH/Icon-App-83.5x83.5@2x.png
rm $DEST_DIR_PATH/Icon-App-1024x1024@1x.png

rm $DEST_DIR_PATH/Icon-App-Dark-20x20@2x.png
rm $DEST_DIR_PATH/Icon-App-Dark-20x20@3x.png
rm $DEST_DIR_PATH/Icon-App-Dark-29x29@2x.png
rm $DEST_DIR_PATH/Icon-App-Dark-29x29@3x.png
rm $DEST_DIR_PATH/Icon-App-Dark-38x38@2x.png
rm $DEST_DIR_PATH/Icon-App-Dark-38x38@3x.png
rm $DEST_DIR_PATH/Icon-App-Dark-40x40@2x.png
rm $DEST_DIR_PATH/Icon-App-Dark-40x40@3x.png
rm $DEST_DIR_PATH/Icon-App-Dark-60x60@2x.png
rm $DEST_DIR_PATH/Icon-App-Dark-60x60@3x.png
rm $DEST_DIR_PATH/Icon-App-Dark-64x64@2x.png
rm $DEST_DIR_PATH/Icon-App-Dark-64x64@3x.png
rm $DEST_DIR_PATH/Icon-App-Dark-68x68@2x.png
rm $DEST_DIR_PATH/Icon-App-Dark-76x76@2x.png
rm $DEST_DIR_PATH/Icon-App-Dark-83.5x83.5@2x.png
rm $DEST_DIR_PATH/Icon-App-Dark-1024x1024@1x.png

rm $DEST_DIR_PATH/Icon-App-Tinted-20x20@2x.png
rm $DEST_DIR_PATH/Icon-App-Tinted-20x20@3x.png
rm $DEST_DIR_PATH/Icon-App-Tinted-29x29@2x.png
rm $DEST_DIR_PATH/Icon-App-Tinted-29x29@3x.png
rm $DEST_DIR_PATH/Icon-App-Tinted-38x38@2x.png
rm $DEST_DIR_PATH/Icon-App-Tinted-38x38@3x.png
rm $DEST_DIR_PATH/Icon-App-Tinted-40x40@2x.png
rm $DEST_DIR_PATH/Icon-App-Tinted-40x40@3x.png
rm $DEST_DIR_PATH/Icon-App-Tinted-60x60@2x.png
rm $DEST_DIR_PATH/Icon-App-Tinted-60x60@3x.png
rm $DEST_DIR_PATH/Icon-App-Tinted-64x64@2x.png
rm $DEST_DIR_PATH/Icon-App-Tinted-64x64@3x.png
rm $DEST_DIR_PATH/Icon-App-Tinted-68x68@2x.png
rm $DEST_DIR_PATH/Icon-App-Tinted-76x76@2x.png
rm $DEST_DIR_PATH/Icon-App-Tinted-83.5x83.5@2x.png
rm $DEST_DIR_PATH/Icon-App-Tinted-1024x1024@1x.png

ln -s $CONTENTS_JSON_PATH $DEST_DIR_PATH/Contents.json

ln -s $ICON_20_2x_PATH $DEST_DIR_PATH/Icon-App-20x20@2x.png
ln -s $ICON_20_3x_PATH $DEST_DIR_PATH/Icon-App-20x20@3x.png
ln -s $ICON_29_2x_PATH $DEST_DIR_PATH/Icon-App-29x29@2x.png
ln -s $ICON_29_3x_PATH $DEST_DIR_PATH/Icon-App-29x29@3x.png
ln -s $ICON_38_2x_PATH $DEST_DIR_PATH/Icon-App-38x38@2x.png
ln -s $ICON_38_3x_PATH $DEST_DIR_PATH/Icon-App-38x38@3x.png
ln -s $ICON_40_2x_PATH $DEST_DIR_PATH/Icon-App-40x40@2x.png
ln -s $ICON_40_3x_PATH $DEST_DIR_PATH/Icon-App-40x40@3x.png
ln -s $ICON_60_2x_PATH $DEST_DIR_PATH/Icon-App-60x60@2x.png
ln -s $ICON_60_3x_PATH $DEST_DIR_PATH/Icon-App-60x60@3x.png
ln -s $ICON_64_2x_PATH $DEST_DIR_PATH/Icon-App-64x64@2x.png
ln -s $ICON_64_3x_PATH $DEST_DIR_PATH/Icon-App-64x64@3x.png
ln -s $ICON_68_2x_PATH $DEST_DIR_PATH/Icon-App-68x68@2x.png
ln -s $ICON_76_2x_PATH $DEST_DIR_PATH/Icon-App-76x76@2x.png
ln -s $ICON_83_5_2x_PATH $DEST_DIR_PATH/Icon-App-83.5x83.5@2x.png
ln -s $ICON_1024_1x_PATH $DEST_DIR_PATH/Icon-App-1024x1024@1x.png


#TODO once the new monero.com icons are out remove if statement
if [ $APP_IOS_TYPE = "cakewallet" ]; then

ln -s $ICON_DARK_20_2x_PATH $DEST_DIR_PATH/Icon-App-Dark-20x20@2x.png
ln -s $ICON_DARK_20_3x_PATH $DEST_DIR_PATH/Icon-App-Dark-20x20@3x.png
ln -s $ICON_DARK_29_2x_PATH $DEST_DIR_PATH/Icon-App-Dark-29x29@2x.png
ln -s $ICON_DARK_29_3x_PATH $DEST_DIR_PATH/Icon-App-Dark-29x29@3x.png
ln -s $ICON_DARK_38_2x_PATH $DEST_DIR_PATH/Icon-App-Dark-38x38@2x.png
ln -s $ICON_DARK_38_3x_PATH $DEST_DIR_PATH/Icon-App-Dark-38x38@3x.png
ln -s $ICON_DARK_40_2x_PATH $DEST_DIR_PATH/Icon-App-Dark-40x40@2x.png
ln -s $ICON_DARK_40_3x_PATH $DEST_DIR_PATH/Icon-App-Dark-40x40@3x.png
ln -s $ICON_DARK_60_2x_PATH $DEST_DIR_PATH/Icon-App-Dark-60x60@2x.png
ln -s $ICON_DARK_60_3x_PATH $DEST_DIR_PATH/Icon-App-Dark-60x60@3x.png
ln -s $ICON_DARK_64_2x_PATH $DEST_DIR_PATH/Icon-App-Dark-64x64@2x.png
ln -s $ICON_DARK_64_3x_PATH $DEST_DIR_PATH/Icon-App-Dark-64x64@3x.png
ln -s $ICON_DARK_68_2x_PATH $DEST_DIR_PATH/Icon-App-Dark-68x68@2x.png
ln -s $ICON_DARK_76_2x_PATH $DEST_DIR_PATH/Icon-App-Dark-76x76@2x.png
ln -s $ICON_DARK_83_5_2x_PATH $DEST_DIR_PATH/Icon-App-Dark-83.5x83.5@2x.png
ln -s $ICON_DARK_1024_1x_PATH $DEST_DIR_PATH/Icon-App-Dark-1024x1024@1x.png

ln -s $ICON_TINTED_20_2x_PATH $DEST_DIR_PATH/Icon-App-Tinted-20x20@2x.png
ln -s $ICON_TINTED_20_3x_PATH $DEST_DIR_PATH/Icon-App-Tinted-20x20@3x.png
ln -s $ICON_TINTED_29_2x_PATH $DEST_DIR_PATH/Icon-App-Tinted-29x29@2x.png
ln -s $ICON_TINTED_29_3x_PATH $DEST_DIR_PATH/Icon-App-Tinted-29x29@3x.png
ln -s $ICON_TINTED_38_2x_PATH $DEST_DIR_PATH/Icon-App-Tinted-38x38@2x.png
ln -s $ICON_TINTED_38_3x_PATH $DEST_DIR_PATH/Icon-App-Tinted-38x38@3x.png
ln -s $ICON_TINTED_40_2x_PATH $DEST_DIR_PATH/Icon-App-Tinted-40x40@2x.png
ln -s $ICON_TINTED_40_3x_PATH $DEST_DIR_PATH/Icon-App-Tinted-40x40@3x.png
ln -s $ICON_TINTED_60_2x_PATH $DEST_DIR_PATH/Icon-App-Tinted-60x60@2x.png
ln -s $ICON_TINTED_60_3x_PATH $DEST_DIR_PATH/Icon-App-Tinted-60x60@3x.png
ln -s $ICON_TINTED_64_2x_PATH $DEST_DIR_PATH/Icon-App-Tinted-64x64@2x.png
ln -s $ICON_TINTED_64_3x_PATH $DEST_DIR_PATH/Icon-App-Tinted-64x64@3x.png
ln -s $ICON_TINTED_68_2x_PATH $DEST_DIR_PATH/Icon-App-Tinted-68x68@2x.png
ln -s $ICON_TINTED_76_2x_PATH $DEST_DIR_PATH/Icon-App-Tinted-76x76@2x.png
ln -s $ICON_TINTED_83_5_2x_PATH $DEST_DIR_PATH/Icon-App-Tinted-83.5x83.5@2x.png
ln -s $ICON_TINTED_1024_1x_PATH $DEST_DIR_PATH/Icon-App-Tinted-1024x1024@1x.png

fi

