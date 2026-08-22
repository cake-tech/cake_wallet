#!/bin/sh
# From the Flutter app root:
#   ./elinux/build.sh          # AOT on the host, RPM in sfosbuild
#   ./elinux/build.sh deploy
#   ./elinux/build.sh clean
#
# Needs a matching Flutter SDK on PATH, plus:
#   FLUTTER_SFOS_HOST  dir with bin/gen_snapshot and icudtl.dat
#   FLUTTER_SFOS_RPMS  dir with flutter-sfos-<ver> and -devel RPMs
set -eu

cd $(dirname $0)

ELINUX=$PWD/elinux
source $ELINUX/flutter-sfos.env

HOST=$PWD/scripts/sfos/flutter-sailfishos/versions/$FLUTTER_VERSION/engine
RPMS=$PWD/scripts/sfos/flutter-sailfishos/versions/$FLUTTER_VERSION/runtime/rpms

for SFOS in $SFOS_VERSION;
do
    ARCH=aarch64

    rm -rf build "$ELINUX"/rpms "$ELINUX"/out "$ELINUX"/bundle \
        "$ELINUX"/build-native "$ELINUX"/*.rpm
    for f in "$ELINUX"/*.in "$ELINUX"/rpm/*.in; do
        [ -f "$f" ] && rm -f "${f%.in}"
    done

    # --- host: Dart AOT + assets ---
    sdk=$(dirname "$(dirname "$(command -v flutter)")")
    test -x "$sdk/bin/flutter"
    test -x "$HOST/bin/gen_snapshot"
    test -f "$HOST/icudtl.dat"

    got=$(flutter --version | awk '/Flutter /{print $2; exit}')
    if [ "$got" != "$FLUTTER_VERSION" ]; then
        echo "Flutter SDK is $got, need $FLUTTER_VERSION" >&2
        exit 1
    fi

    pkg=cake_wallet
    bundle=build/sfos/$SFOS/bundle
    ver=$(awk '/^version:/{print $2; exit}' pubspec.yaml)
    VERSION=${ver%%+*}
    RELEASE=${ver##*+}
    
    mkdir -p "$bundle/lib" "$bundle/data/flutter_assets"

    flutter pub get
    flutter build bundle --release --asset-dir="$bundle/data/flutter_assets"

    dill=.dart_tool/flutter-sfos/app.dill
    mkdir -p "$(dirname "$dill")"
    frontend=$sdk/bin/cache/dart-sdk/bin/snapshots/frontend_server_aot.dart.snapshot
    patched=$sdk/bin/cache/artifacts/engine/common/flutter_patched_sdk_product
    [ -d "$patched" ] || patched=$sdk/bin/cache/artifacts/engine/common/flutter_patched_sdk

    "$sdk/bin/cache/dart-sdk/bin/dartaotruntime" "$frontend" \
        --sdk-root "$patched" --target=flutter \
        --no-print-incremental-dependencies \
        -Ddart.vm.profile=false -Ddart.vm.product=true \
        --aot --tfa \
        --packages .dart_tool/package_config.json \
        --output-dill "$dill" \
        "package:${pkg}/main.dart"

    "$HOST/bin/gen_snapshot" \
        --deterministic --snapshot_kind=app-aot-elf --strip \
        --elf="$bundle/lib/libapp.so" \
        "$dill"
    cp -f "$HOST/icudtl.dat" "$bundle/data/icudtl.dat"

    # --- device: native bits + RPM ---
    for f in "$ELINUX"/*.in "$ELINUX"/rpm/*.in; do
        [ -f "$f" ] || continue
        sed -e "s|@FLUTTER_VERSION@|$FLUTTER_VERSION|g" \
            -e "s|@VERSION@|$VERSION|g" \
            -e "s|@RELEASE@|$RELEASE|g" \
            "$f" > "${f%.in}"
    done
    chmod +x "$ELINUX"/*.sh

    rm -rf "$ELINUX/bundle"
    cp -a "$bundle" "$ELINUX/bundle"
    cp -f "$(ls -t "$RPMS"/flutter-sfos-"$FLUTTER_VERSION"-"$FLUTTER_VERSION"-*.aarch64.rpm | grep -v debug | head -1)" \
        "$(ls -t "$RPMS"/flutter-sfos-"$FLUTTER_VERSION"-devel-"$FLUTTER_VERSION"-*.aarch64.rpm | grep -v debug | head -1)" \
        "$ELINUX/"

    sfosbuild "$SFOS" "$ARCH" elinux
done