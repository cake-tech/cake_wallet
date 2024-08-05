#!/bin/sh

if [ -z "$APP_MACOS_TYPE" ]; then
	echo "Please set APP_MACOS_TYPE"
	exit 1
fi

DIR=$(dirname "$0")

case $APP_MACOS_TYPE in
	"monero.com") $DIR/build_monero_all.sh ;;
	"cakewallet") $DIR/build_monero_all.sh && $DIR/build_haven_all.sh && $DIR/build_decred.sh ;;
	"haven")      $DIR/build_haven_all.sh ;;
esac
