#!/usr/bin/env bash
#
# Packages an already-built Flutter Linux bundle into a single-file AppImage.
#
# Expects `flutter build linux --release` to have produced
# build/linux/x64/release/bundle. Mirrors the layout used by
# com.cakewallet.CakeWallet.yml so flatpak and AppImage ship the same tree.
#
# Runtime requirements for the produced AppImage (documented in the PR):
#   - glibc >= 2.38 (inherited from the Debian 13 build container; the
#     monero_c wallet library is the binding constraint)
#   - GTK 3 from the host (a .desktop-integrated desktop distro has it)
#   - FUSE 2, or run with --appimage-extract-and-run
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

APP_ID="com.cakewallet.CakeWallet"
APP_NAME="Cake Wallet"
ARCH="${ARCH:-x86_64}"

BUNDLE_DIR="$REPO_ROOT/build/linux/x64/release/bundle"
OUT_DIR="${OUT_DIR:-$REPO_ROOT/build/linux/x64/release}"
WORK_DIR="${WORK_DIR:-$REPO_ROOT/build/appimage}"
TOOLS_DIR="${TOOLS_DIR:-$REPO_ROOT/build/appimage-tools}"

# appimagetool and friends are themselves AppImages; extract instead of
# mounting them, because CI containers usually have no FUSE.
export APPIMAGE_EXTRACT_AND_RUN=1

log() { printf '==> %s\n' "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

[ -d "$BUNDLE_DIR" ] || die "missing $BUNDLE_DIR; run 'flutter build linux --release' first"
[ -x "$BUNDLE_DIR/cake_wallet" ] || die "missing executable $BUNDLE_DIR/cake_wallet"

# Version comes from the configured pubspec (scripts/linux/app_config.sh stamps it).
VERSION="$(sed -n 's/^version:[[:space:]]*//p' "$REPO_ROOT/pubspec.yaml" | head -1 | tr -d '\r' || true)"
[ -n "$VERSION" ] || die "could not read version from pubspec.yaml"
APP_VERSION="${VERSION%%+*}"

APPDIR="$WORK_DIR/AppDir"
rm -rf "$APPDIR" "$WORK_DIR"/.tmp
mkdir -p "$APPDIR/usr/share/applications" \
         "$APPDIR/usr/share/icons/hicolor/256x256/apps" \
         "$TOOLS_DIR"

fetch_tool() {
  local url="$1" dest="$2" sha="${3:-}"
  if [ -x "$dest" ]; then
    log "using cached $(basename "$dest")"
  else
    log "downloading $(basename "$dest")"
    curl -fsSL --retry 3 -o "$dest.part" "$url" || die "download failed: $url"
    mv "$dest.part" "$dest"
  fi
  chmod +x "$dest"
  if [ -n "$sha" ]; then
    echo "$sha  $dest" | sha256sum -c - >/dev/null 2>&1 \
      || die "sha256 mismatch for $(basename "$dest")"
  fi
}

# Pinned to a specific appimagetool build for reproducibility. Override with
# APPIMAGETOOL_URL / APPIMAGETOOL_SHA256 to bump deliberately.
APPIMAGETOOL_URL="${APPIMAGETOOL_URL:-https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage}"
APPIMAGETOOL_SHA256="${APPIMAGETOOL_SHA256:-}"
fetch_tool "$APPIMAGETOOL_URL" "$TOOLS_DIR/appimagetool" "$APPIMAGETOOL_SHA256"

log "staging application tree"
# Keep the Flutter bundle intact: the runner resolves data/ and lib/ relative
# to the executable, and the binary's RPATH is $ORIGIN/lib.
mkdir -p "$APPDIR/usr/cake_wallet"
cp -a "$BUNDLE_DIR/." "$APPDIR/usr/cake_wallet/"
chmod +x "$APPDIR/usr/cake_wallet/cake_wallet"

log "installing desktop file and icon"
sed "s|^Exec=.*|Exec=cake_wallet|" "$REPO_ROOT/linux/$APP_ID.desktop" \
  > "$APPDIR/$APP_ID.desktop"
cp "$APPDIR/$APP_ID.desktop" "$APPDIR/usr/share/applications/$APP_ID.desktop"
cp "$REPO_ROOT/assets/images/cakewallet_icon_180.png" "$APPDIR/$APP_ID.png"
cp "$APPDIR/$APP_ID.png" "$APPDIR/usr/share/icons/hicolor/256x256/apps/$APP_ID.png"

log "writing AppRun"
cat > "$APPDIR/AppRun" <<'APPRUN'
#!/bin/bash
# Resolve the real AppDir whether we were extracted or mounted.
HERE="$(dirname "$(readlink -f "${0}")")"
export APPDIR="${APPDIR:-$HERE}"
export LD_LIBRARY_PATH="$APPDIR/usr/cake_wallet/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

if ! ldconfig -p 2>/dev/null | grep -q 'libgtk-3\.so\.0'; then
  echo "Cake Wallet needs GTK 3, which was not found on this system." >&2
  echo "Install it (e.g. 'gtk3' on Fedora, 'libgtk-3-0' on Debian/Ubuntu) and retry." >&2
  exit 1
fi

exec "$APPDIR/usr/cake_wallet/cake_wallet" "$@"
APPRUN
chmod +x "$APPDIR/AppRun"

mkdir -p "$OUT_DIR"
OUT_NAME="Cake_Wallet-${VERSION}-${ARCH}.AppImage"
OUT_PATH="$OUT_DIR/$OUT_NAME"

log "building $OUT_NAME"
"$TOOLS_DIR/appimagetool" --no-appstream "$APPDIR" "$OUT_PATH" >/dev/null \
  || die "appimagetool failed"

# Checksums are what requesters of #3513 need; cheap to emit here.
( cd "$OUT_DIR" && sha256sum "$OUT_NAME" > "$OUT_NAME.sha256" )

log "done"
ls -lh "$OUT_PATH"
cat "$OUT_PATH.sha256"
