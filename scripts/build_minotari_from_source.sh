#!/bin/bash
# Builds cw_tari_wallet from source at a pinned commit, with its own release script,
# into the same zips its GitHub release publishes. Run by
# `prepare_minotari.sh --from-source`; not meant to be called directly.
#
# Usage: build_minotari_from_source.sh <tag> <sha> <out-dir> <asset>...
#   asset: dart, android, ios, macos, linux-x86_64, linux-aarch64 or windows
#
# Needs git, a Rust toolchain with rustup, GNU make and python3. Android also needs
# ANDROID_NDK_HOME (the release uses NDK 28.2.13676358); iOS and macOS need Xcode.

set -euo pipefail

die() { echo "error: $*" >&2; exit 1; }

[ $# -ge 4 ] || die "usage: $0 <tag> <sha> <out-dir> <asset>..."
tag="$1"
sha="$2"
out="$(mkdir -p "$3" && cd "$3" && pwd)"
shift 3

for tool in git cargo rustup make; do command -v "$tool" >/dev/null || die "$tool is required"; done
command -v python >/dev/null || command -v python3 >/dev/null || die "python3 is required"

src="$(mktemp -d)"
trap 'rm -rf "$src"' EXIT

echo "Building cw_tari_wallet $tag ($sha) from source"
git -C "$src" init -q
git -C "$src" fetch -q --depth 1 https://github.com/tari-project/cw_tari_wallet.git "$sha"
git -C "$src" checkout -q FETCH_HEAD
[ "$(git -C "$src" rev-parse HEAD)" = "$sha" ] || die "checkout is not $sha"
cd "$src"

# The release's own Rust targets per asset (cw_tari_wallet .github/workflows/release.yml).
targets_for() {
  case "$1" in
    android) echo aarch64-linux-android armv7-linux-androideabi x86_64-linux-android ;;
    ios) echo aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios ;;
    macos) echo aarch64-apple-darwin x86_64-apple-darwin ;;
    linux-x86_64) echo x86_64-unknown-linux-gnu ;;
    linux-aarch64) echo aarch64-unknown-linux-gnu ;;
    windows) echo x86_64-pc-windows-msvc ;;
  esac
}

cargo fetch --locked
for asset in "$@"; do
  case "$asset" in
    dart)
      # Exactly what the release ships: the committed bindings at this commit.
      git archive --format=zip --prefix=dart/ -o "$out/cw_tari_wallet-$tag-dart.zip" HEAD:.dart
      ;;
    android | ios | macos | linux-x86_64 | linux-aarch64 | windows)
      # shellcheck disable=SC2046
      rustup target add $(targets_for "$asset")
      # build.sh wants a relative output dir (Windows Python cannot read Git Bash paths).
      TARI_TARGET_NETWORK=mainnet ./scripts/release/build.sh "$asset" "$tag" dist
      mv "dist/cw_tari_wallet-$tag-$asset.zip" "$out/"
      ;;
    *) die "unknown asset: $asset" ;;
  esac
done
