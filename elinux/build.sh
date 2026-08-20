#!/bin/sh
# From the Flutter app root:
#   ./elinux/build.sh
#   ./elinux/build.sh clean
#
# Needs:
#   FLUTTER_SFOS_RPMS  dir with flutter-sfos-<ver> and -devel RPMs
set -xeu

cd $(dirname "$0")/..
ELINUX=$PWD/elinux

. "$ELINUX/flutter-sfos.env"

VERSION=$(sed -n 's/^CAKEWALLET_VERSION="\(.*\)"/\1/p' scripts/linux/app_env.sh)
BUILD_NUMBER=$(sed -n 's/^CAKEWALLET_BUILD_NUMBER=//p' scripts/linux/app_env.sh)

RPMS=./scripts/sfos/flutter-sailfishos/versions/$FLUTTER_VERSION/runtime/rpms
for SFOS in $SFOS_VERSIONS;
do
	ARCH=aarch64

	rm -rf build "$ELINUX"/rpms "$ELINUX"/out "$ELINUX"/bundle \
		"$ELINUX"/build-native rpms
	rm -f ./*.rpm "$ELINUX"/*.rpm
	for f in "$ELINUX"/*.in rpm/*.in; do
		[ -f "$f" ] && rm -f "${f%.in}"
	done

    test -d rpm
    test -x "$ELINUX/build.sh"

	for f in "$ELINUX"/*.in rpm/*.in; do
		[ -f "$f" ] || continue
		sed \
			-e "s|@FLUTTER_VERSION@|$FLUTTER_VERSION|g" \
			-e "s|@VERSION@|$VERSION|g" \
			-e "s|@BUILD_NUMBER@|$BUILD_NUMBER|g" \
			"$f" > "${f%.in}"
	done
	chmod +x "$ELINUX"/*.sh

	rm -f ./flutter-sfos-"$FLUTTER_VERSION"-*.rpm
	cp -f "$(ls -t "$RPMS"/flutter-sfos-"$FLUTTER_VERSION"-"$FLUTTER_VERSION"-*.$ARCH.rpm | grep -v debug | head -1)" \
		"$(ls -t "$RPMS"/flutter-sfos-"$FLUTTER_VERSION"-devel-"$FLUTTER_VERSION"-*.$ARCH.rpm | grep -v debug | head -1)" \
		./

	sfosbuild "$SFOS" "$ARCH" .
done
