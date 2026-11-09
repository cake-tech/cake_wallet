#!/bin/bash
# Downloads the pinned cw_tari_wallet release bundle, verifies it, and unpacks the
# native libraries for the given platforms plus the FRB Dart bindings into cw_minotari.
# Usage: scripts/prepare_minotari.sh <android|ios|macos|linux|windows>...

set -euo pipefail

# To bump: set the tag and the commit it points at, then the sha256 of that
# release's SHA256SUMS asset (`sha256sum SHA256SUMS`). The digest pins every zip.
CW_TARI_WALLET_TAG="v0.2.0"
CW_TARI_WALLET_SHA="7d8d1c4d57f55c1c3a0a9cc67aed354e0c411214"
CW_TARI_WALLET_SUMS_SHA256="PENDING-v0.2.0-release-SHA256SUMS-digest"

LIB=rust_lib_flutter_rust_wallet
URL="https://github.com/tari-project/cw_tari_wallet/releases/download/$CW_TARI_WALLET_TAG"

cd "$(dirname "$0")/../cw_minotari"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Preparing cw_tari_wallet $CW_TARI_WALLET_TAG ($CW_TARI_WALLET_SHA)"
curl -fsSL -o "$TMP/SHA256SUMS" "$URL/SHA256SUMS"
(cd "$TMP" && echo "$CW_TARI_WALLET_SUMS_SHA256  SHA256SUMS" | sha256sum -c -)

# unpack <asset> <dir>: downloads cw_tari_wallet-<tag>-<asset>.zip, checks it
# against SHA256SUMS and extracts it into <dir>.
unpack() {
  local zip="cw_tari_wallet-$CW_TARI_WALLET_TAG-$1.zip"
  curl -fsSL -o "$TMP/$zip" "$URL/$zip"
  (cd "$TMP" && awk -v f="$zip" '$2 == f' SHA256SUMS | sha256sum -c -)
  mkdir -p "$2"
  unzip -q -o "$TMP/$zip" -d "$2"
}

unpack dart "$TMP/dart"
rm "$TMP/dart/dart/pubspec.yaml"
rm -rf lib/src/rust
mv "$TMP/dart/dart" lib/src/rust

for platform in "$@"; do
  case "$platform" in
    android)
      rm -rf android/src/main/jniLibs
      unpack android android/src/main
      ;;
    ios)
      rm -rf ios/Frameworks
      unpack ios ios/Frameworks
      ;;
    macos)
      # FRB opens <lib>.framework/<lib> on macOS, so the bundle's dylib is wrapped
      # in a versioned framework that CocoaPods embeds and Xcode re-signs.
      rm -rf macos/Frameworks
      unpack macos "$TMP/macos"
      fw="macos/Frameworks/$LIB.framework"
      mkdir -p "$fw/Versions/A/Resources"
      mv "$TMP/macos/lib$LIB.dylib" "$fw/Versions/A/$LIB"
      install_name_tool -id "@rpath/$LIB.framework/Versions/A/$LIB" "$fw/Versions/A/$LIB"
      cat > "$fw/Versions/A/Resources/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$LIB</string>
    <key>CFBundleIdentifier</key>
    <string>com.cakewallet.minotari</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$LIB</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>${CW_TARI_WALLET_TAG#v}</string>
    <key>CFBundleVersion</key>
    <string>1</string>
</dict>
</plist>
EOF
      ln -s A "$fw/Versions/Current"
      ln -s "Versions/Current/$LIB" "$fw/$LIB"
      ln -s Versions/Current/Resources "$fw/Resources"
      # install_name_tool invalidated the bundle's ad hoc signature.
      codesign --force --sign - "$fw"
      ;;
    linux)
      rm -rf linux/lib
      unpack "linux-$(uname -m)" linux/lib
      ;;
    windows)
      rm -rf windows/lib
      unpack windows windows/lib
      ;;
    *)
      echo "unknown platform: $platform (expected android, ios, macos, linux or windows)" >&2
      exit 1
      ;;
  esac
done

echo "Minotari prepared for: dart $*"
