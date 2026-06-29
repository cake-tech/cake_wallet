#!/bin/bash
set -x -e
cd $(dirname $0)
cd ..

for i in cw_bitcoin cw_bitcoin_cash cw_core cw_decred cw_dogecoin cw_evm cw_monero cw_mweb cw_nano cw_solana cw_tron cw_zano cw_zcash lib;
do
    dart fix --apply $i/
    dart format --line-length=100 $i/
    if [[ ! "x$ABORT_ON_CHANGE" == "x" ]];
    then
        if [[ ! -z "$(git status --porcelain -- $(find $i))" ]];
        then
            echo "Please run scripts/lint.sh ($i has changes)"
            exit 1
        fi
    fi
done
