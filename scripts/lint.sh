#!/bin/bash
set -x -e
cd "$(dirname "$0")"
cd ..

for i in cw_bitcoin cw_bitcoin_cash cw_core cw_decred cw_dogecoin cw_evm cw_monero cw_mweb cw_nano cw_solana cw_tron cw_zano cw_zcash lib;
do
    find "$i" -type f -name "*.dart" -newermt "2026-06-29 23:59:59" -exec bash -c 'dart fix --apply "$@" && dart format --line-length=100 "$@"' _ {} +
    if [[ -n "$ABORT_ON_CHANGE" ]]; then
        if [[ -n "$(git status --porcelain -- "$i")" ]]; then
            echo "Please run scripts/lint.sh ($i has changes)"
            exit 1
        fi
    fi
done
