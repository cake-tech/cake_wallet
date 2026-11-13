#!/usr/bin/env bash

set -euo pipefail

# Prints `HeightCheckpoint(<block time>, <height>),` lines for cw_core/lib/get_height_by_date_btc.dart.
# Usage: scripts/gen_btc_height_checkpoints.sh [first_height] [step]
# To refresh: run it and replace the lines inside `_table` with the output.

API="${MEMPOOL_API:-https://mempool.cakewallet.com/api}"
step="${2:-10000}"
first="${1:-$step}"
tip=$(curl -fsS "$API/blocks/tip/height")

for ((h = first; h <= tip; h += step)); do
  hash=$(curl -fsS "$API/block-height/$h")
  ts=$(curl -fsS "$API/block/$hash" | grep -o '"timestamp":[0-9]*' | cut -d: -f2)
  echo "    HeightCheckpoint($ts, $h),"
done
