#!/bin/bash
# Downloads the pinned cw_tari_wallet release bundle, verifies it, and unpacks the
# native libraries for the given platforms plus the FRB Dart bindings into cw_minotari.
# Usage: scripts/prepare_minotari.sh [--from-source] <android|ios|macos|linux|windows>...
#
# --from-source builds the same pinned commit locally instead of downloading it
# (scripts/build_minotari_from_source.sh lists what that needs), then reports whether
# each built zip matches the published release.

set -euo pipefail

# To bump: set the tag and the commit it points at, then the sha256 of that
# release's SHA256SUMS asset. The digest pins every zip:
#   gh release download <tag> -R tari-project/cw_tari_wallet -p SHA256SUMS && sha256sum SHA256SUMS
# Each run replaces cw_minotari/lib/src/rust; run ./model_generator.sh afterwards.
CW_TARI_WALLET_TAG="v0.3.1"
CW_TARI_WALLET_SHA="93e066234b53c7c782707fdff40b361fbe36aa8d"
CW_TARI_WALLET_SUMS_SHA256="93cb1f9aee909261705a366768549bd03fd9ff523eb1b0afe1e014e39e5c4502"

LIB=minotari_wallet_ffi
REPO="https://github.com/tari-project/cw_tari_wallet"
URL="$REPO/releases/download/$CW_TARI_WALLET_TAG"

die() { echo "error: $*" >&2; exit 1; }

# Each platform's library folder carries a stamp of the release it came from, so
# folders left on an older release (the bindings are always replaced) get removed.
STAMP="$CW_TARI_WALLET_TAG $CW_TARI_WALLET_SHA"
lib_dir() {
  case "$1" in
    android) echo android/src/main/jniLibs ;;
    ios) echo ios/Frameworks ;;
    macos) echo macos/Frameworks ;;
    linux) echo linux/lib ;;
    windows) echo windows/lib ;;
  esac
}

FROM_SOURCE=0
if [ "${1:-}" = --from-source ]; then
  FROM_SOURCE=1
  shift
fi
[ $# -gt 0 ] || die "usage: $0 [--from-source] <android|ios|macos|linux|windows>..."
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

SCRIPTS="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPTS/../cw_minotari"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Preparing cw_tari_wallet $CW_TARI_WALLET_TAG ($CW_TARI_WALLET_SHA)"
# An annotated tag lists the tag object, then its peeled commit; a lightweight tag only the commit.
tag_sha="$(git ls-remote "$REPO.git" "refs/tags/$CW_TARI_WALLET_TAG" "refs/tags/$CW_TARI_WALLET_TAG^{}" | tail -n1 | cut -f1)"
[ "$tag_sha" = "$CW_TARI_WALLET_SHA" ] || die "$CW_TARI_WALLET_TAG points at '$tag_sha', expected $CW_TARI_WALLET_SHA"

curl -fsSL -o "$TMP/SHA256SUMS" "$URL/SHA256SUMS"
# --strict: without it, macOS sha256sum accepts malformed or empty input.
(cd "$TMP" && echo "$CW_TARI_WALLET_SUMS_SHA256  SHA256SUMS" | sha256sum -c --strict -)

if [ "$FROM_SOURCE" = 1 ]; then
  "$SCRIPTS/build_minotari_from_source.sh" "$CW_TARI_WALLET_TAG" "$CW_TARI_WALLET_SHA" "$TMP" "${assets[@]}"
fi

# Everything is fetched and checked before cw_minotari is touched.
for asset in "${assets[@]}"; do
  zip="cw_tari_wallet-$CW_TARI_WALLET_TAG-$asset.zip"
  line="$(awk -v f="$zip" '$2 == f' "$TMP/SHA256SUMS")"
  [ -n "$line" ] || die "$zip is not listed in SHA256SUMS"
  if [ "$FROM_SOURCE" = 1 ]; then
    # Informational only: compares the files inside the built zip with the published
    # one. Native builds are rarely identical across machines and toolchains, so a
    # difference is not an error.
    mkdir -p "$TMP/published" "$TMP/published-$asset"
    curl -fsSL -o "$TMP/published/$zip" "$URL/$zip"
    (cd "$TMP/published" && echo "$line" | sha256sum -c --strict - >/dev/null)
    unzip -q -o "$TMP/published/$zip" -d "$TMP/published-$asset"
  else
    curl -fsSL -o "$TMP/$zip" "$URL/$zip"
    (cd "$TMP" && echo "$line" | sha256sum -c --strict -)
  fi
  mkdir -p "$TMP/$asset"
  unzip -q -o "$TMP/$zip" -d "$TMP/$asset"
  if [ "$FROM_SOURCE" = 1 ]; then
    if diff -rq "$TMP/published-$asset" "$TMP/$asset" >/dev/null; then
      echo "$zip: built from source; same files as the published release"
    else
      echo "$zip: built from source; differs from the published release:"
      diff -rq "$TMP/published-$asset" "$TMP/$asset" | sed 's|'"$TMP"'/||g; s/^/  /' || true
    fi
  fi
done

rm "$TMP/dart/dart/pubspec.yaml"
rm -rf lib/src/rust
mkdir -p lib/src
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
    <string>1.0</string>
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
  # Dotfile beside the libraries, not inside a framework, so no build packages it.
  echo "$STAMP" > "$(lib_dir "$platform")/.cw_tari_wallet"
done

for platform in android ios macos linux windows; do
  dir="$(lib_dir "$platform")"
  if [ -d "$dir" ] && [ "$(cat "$dir/.cw_tari_wallet" 2>/dev/null)" != "$STAMP" ]; then
    rm -rf "$dir"
    echo "removed stale $platform libs; re-run prepare_minotari.sh $platform"
  fi
done

echo "Minotari prepared for: dart $*"
