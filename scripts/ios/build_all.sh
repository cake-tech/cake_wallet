#!/bin/sh

if [ -z "$APP_IOS_TYPE" ]; then
	echo "Please set APP_IOS_TYPE"
	exit 1
fi

DIR=$(dirname "$0")

case $APP_IOS_TYPE in
	"monero.com") $DIR/build_monero_all.sh ;;
	"cakewallet") $DIR/build_monero_all.sh && $DIR/build_haven.sh ;;
	"haven")      $DIR/build_haven_all.sh ;;
esac
