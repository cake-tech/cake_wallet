#!/usr/bin/env bash
#
# Fetch the PIVX Sapling proving parameters into cw_pivx/assets/params/ so they
# get bundled into the app. Idempotent: skips download when the file already
# exists with the correct SHA256. CI / fresh clones run this before building.
#
# The params are the universal Sapling params (byte-identical to Zcash's).
set -euo pipefail

# Repo root = parent of this script's dir.
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST_DIR="$ROOT_DIR/cw_pivx/assets/params"

# name  url  sha256
PARAMS=(
  "sapling-spend.params|https://duddino.com/sapling-spend.params|8e48ffd23abb3a5fd9c5589204f32d9c31285a04b78096ba40a79b75677efc13"
  "sapling-output.params|https://duddino.com/sapling-output.params|2f0ebbcbb9bb0bcffe95a397e7eba89c29eb4dde6191c339db88570e3f3fb0e4"
)

# sha256 of a file, portable across macOS (shasum) and Linux (sha256sum).
sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

mkdir -p "$DEST_DIR"

for entry in "${PARAMS[@]}"; do
  IFS='|' read -r name url want <<<"$entry"
  dest="$DEST_DIR/$name"

  if [[ -f "$dest" ]] && [[ "$(sha256_of "$dest")" == "$want" ]]; then
    echo "OK (cached): $name"
    continue
  fi

  echo "Downloading $name ..."
  curl -fL --retry 3 -o "$dest.tmp" "$url"

  got="$(sha256_of "$dest.tmp")"
  if [[ "$got" != "$want" ]]; then
    rm -f "$dest.tmp"
    echo "ERROR: SHA256 mismatch for $name" >&2
    echo "  expected $want" >&2
    echo "  got      $got" >&2
    exit 1
  fi

  mv "$dest.tmp" "$dest"
  echo "OK: $name"
done

echo "PIVX Sapling params ready in $DEST_DIR"
