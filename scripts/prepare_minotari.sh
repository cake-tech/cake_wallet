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
REPO="https://github.com/tari-project/cw_tari_wallet"
URL="$REPO/releases/download/$CW_TARI_WALLET_TAG"

die() { echo "error: $*" >&2; exit 1; }

[ $# -gt 0 ] || die "usage: $0 <android|ios|macos|linux|windows>..."
for tool in curl unzip sha256sum git; do command -v "$tool" >/dev/null || die "$tool is required"; done

[[ "$CW_TARI_WALLET_SUMS_SHA256" =~ ^[0-9a-f]{64}$ ]] || die "CW_TARI_WALLET_SUMS_SHA256 is not a sha256 digest"

assets=(dart)
for platform in "$@"; do
  case "$platform" in
    android | ios | macos | windows) assets+=("$platform") ;;
    linux) assets+=("linux-$(uname -m)") ;;
    *) die "unknown platform: $platform (expected android, ios, macos, linux or windows)" ;;
  esac
done

cd "$(dirname "$0")/../cw_minotari"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Preparing cw_tari_wallet $CW_TARI_WALLET_TAG ($CW_TARI_WALLET_SHA)"
# An annotated tag lists the tag object, then its peeled commit; a lightweight tag only the commit.
tag_sha="$(git ls-remote "$REPO.git" "refs/tags/$CW_TARI_WALLET_TAG" "refs/tags/$CW_TARI_WALLET_TAG^{}" | tail -n1 | cut -f1)"
[ "$tag_sha" = "$CW_TARI_WALLET_SHA" ] || die "$CW_TARI_WALLET_TAG points at '$tag_sha', expected $CW_TARI_WALLET_SHA"

curl -fsSL -o "$TMP/SHA256SUMS" "$URL/SHA256SUMS"
# --strict: without it, macOS sha256sum accepts malformed or empty input.
(cd "$TMP" && echo "$CW_TARI_WALLET_SUMS_SHA256  SHA256SUMS" | sha256sum -c --strict -)

# Everything is downloaded and verified before cw_minotari is touched.
for asset in "${assets[@]}"; do
  zip="cw_tari_wallet-$CW_TARI_WALLET_TAG-$asset.zip"
  line="$(awk -v f="$zip" '$2 == f' "$TMP/SHA256SUMS")"
  [ -n "$line" ] || die "$zip is not listed in SHA256SUMS"
  curl -fsSL -o "$TMP/$zip" "$URL/$zip"
  (cd "$TMP" && echo "$line" | sha256sum -c --strict -)
  mkdir -p "$TMP/$asset"
  unzip -q -o "$TMP/$zip" -d "$TMP/$asset"
done

rm "$TMP/dart/dart/pubspec.yaml"
rm -rf lib/src/rust
mv "$TMP/dart/dart" lib/src/rust

for platform in "$@"; do
  case "$platform" in
    android)
      rm -rf android/src/main/jniLibs
      mv "$TMP/android/jniLibs" android/src/main/jniLibs
      ;;
    ios)
      rm -rf ios/Frameworks
      mv "$TMP/ios" ios/Frameworks
      ;;
    macos)
      # FRB opens <lib>.framework/<lib> on macOS, so the bundle's dylib is wrapped
      # in a versioned framework that CocoaPods embeds and Xcode re-signs.
      fw="$TMP/$LIB.framework"
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
      rm -rf macos/Frameworks
      mkdir -p macos/Frameworks
      mv "$fw" macos/Frameworks/
      ;;
    linux)
      rm -rf linux/lib
      mv "$TMP/linux-$(uname -m)" linux/lib
      ;;
    windows)
      rm -rf windows/lib
      mv "$TMP/windows" windows/lib
      ;;
  esac
done

echo "Minotari prepared for: dart $*"
