#!/bin/bash
set -x -e
cd "$(dirname "$0")"

# PIVX Sapling Rust sources live in-tree at cw_pivx/rust, so unlike Zcash
# there is nothing to clone or prepare; build the library straight from source.
../../cw_pivx/scripts/build_android.sh
