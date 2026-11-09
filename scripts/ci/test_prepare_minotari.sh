#!/bin/bash
# Offline test of scripts/prepare_minotari.sh: runs a copy pointed at a local fake
# release and tag, checks that failed verification leaves cw_minotari untouched and
# that a good bundle installs into a clean checkout. macOS is not covered (it needs
# Apple's install_name_tool and codesign).

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PREPARE="$ROOT/scripts/prepare_minotari.sh"
LIB=rust_lib_flutter_rust_wallet
TAG="$(sed -n 's/^CW_TARI_WALLET_TAG="\(.*\)"$/\1/p' "$PREPARE")"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT

# Fake upstream: the pinned tag in a local repo, release assets under a file:// URL.
git init -q "$T/upstream.git"
git -C "$T/upstream.git" -c user.name=test -c user.email=test@example.com commit -q --allow-empty -m test
git -C "$T/upstream.git" -c user.name=test -c user.email=test@example.com tag -a -m test "$TAG"
SHA="$(git -C "$T/upstream.git" rev-parse HEAD)"
DIST="$T/upstream/releases/download/$TAG"
mkdir -p "$DIST"

stage() { # <asset> <file>...: zips empty placeholder files as the release asset
  local asset="$1" dir="$T/stage/$1"
  shift
  for f in "$@"; do mkdir -p "$dir/$(dirname "$f")" && echo "$asset" > "$dir/$f"; done
  (cd "$dir" && zip -qr "$DIST/cw_tari_wallet-$TAG-$asset.zip" .)
}
stage dart dart/pubspec.yaml dart/frb_generated.dart
stage android jniLibs/arm64-v8a/lib$LIB.so
stage ios "$LIB.xcframework/Info.plist"
stage "linux-$(uname -m)" "lib$LIB.so"
stage windows "$LIB.dll"
(cd "$DIST" && sha256sum -- *.zip > SHA256SUMS && cp -R . "$T/good")
GOOD="$(sha256sum "$DIST/SHA256SUMS" | cut -d' ' -f1)"

# A clean checkout of cw_minotari (no lib/src) next to the script copy.
git -C "$ROOT" archive HEAD cw_minotari | tar -x -C "$T"
mkdir "$T/scripts"

prepare() { # <pinned SHA256SUMS digest> <platform>...
  sed -e "s|^REPO=.*|REPO=\"file://$T/upstream\"|" \
      -e "s|^CW_TARI_WALLET_SHA=.*|CW_TARI_WALLET_SHA=\"$SHA\"|" \
      -e "s|^CW_TARI_WALLET_SUMS_SHA256=.*|CW_TARI_WALLET_SUMS_SHA256=\"$1\"|" \
      "$PREPARE" > "$T/scripts/prepare_minotari.sh"
  shift
  bash "$T/scripts/prepare_minotari.sh" "$@"
}

state() { (cd "$T/cw_minotari" && find . | sort && find . -type f -exec sha256sum {} + | sort); }

expect_fail() { # <name> <digest> <platform>...
  local name="$1" before
  shift
  before="$(state)"
  if prepare "$@" > "$T/log" 2>&1; then cat "$T/log"; echo "FAIL: $name succeeded" >&2; exit 1; fi
  [ "$(state)" = "$before" ] || { echo "FAIL: $name changed cw_minotari" >&2; exit 1; }
  echo "ok: $name fails ($(tail -n1 "$T/log"))"
}

restore() { rm -rf "$DIST" && cp -R "$T/good" "$DIST"; }

expect_fail "wrong pinned digest" "$(printf '%064d' 0)" android

echo tampered >> "$DIST/cw_tari_wallet-$TAG-android.zip"
expect_fail "tampered zip" "$GOOD" android
restore

grep -v -- "-android.zip" "$T/good/SHA256SUMS" > "$DIST/SHA256SUMS"
expect_fail "zip missing from SHA256SUMS" "$(sha256sum "$DIST/SHA256SUMS" | cut -d' ' -f1)" android
restore

[ ! -e "$T/cw_minotari/lib/src" ] || { echo "FAIL: checkout already has lib/src" >&2; exit 1; }
prepare "$GOOD" android ios linux windows > "$T/log" 2>&1 || { cat "$T/log"; echo "FAIL: good bundle" >&2; exit 1; }
cd "$T/cw_minotari"
for f in lib/src/rust/frb_generated.dart \
         android/src/main/jniLibs/arm64-v8a/lib$LIB.so \
         ios/Frameworks/$LIB.xcframework/Info.plist \
         linux/lib/lib$LIB.so \
         windows/lib/$LIB.dll; do
  [ -f "$f" ] || { echo "FAIL: good bundle did not install $f" >&2; exit 1; }
done
[ ! -e lib/src/rust/pubspec.yaml ] || { echo "FAIL: bindings pubspec.yaml installed" >&2; exit 1; }
echo "ok: good bundle installs into a clean checkout"
