#!/bin/bash
set -x -e

pids=()

for cwcoin in cw_{core,evm,monero,bitcoin,nano,bitcoin_cash,solana,tron,wownero,zano,decred,dogecoin,zcash}
do
    if [[ "x$1" == "xasync" ]];
    then
        env PUB_CACHE=$HOME/.cache/pub-cache-$cwcoin bash -c "cd $cwcoin; flutter pub get; dart run build_runner build --delete-conflicting-outputs; cd .." &
        pids+=($!)
    else
        cd $cwcoin; flutter pub get; dart run build_runner build --delete-conflicting-outputs; cd ..
    fi
done
for cwcoin in cw_mweb;
do
    if [[ "x$1" == "xasync" ]];
    then
        bash -c "cd $cwcoin; flutter pub get; cd .." &
        pids+=($!)
    else
        cd $cwcoin; flutter pub get; cd ..
    fi
done

for pid in "${pids[@]}"; do
    if ! wait "$pid"; then
        ec=$?
        echo "Error: Failed to generate models: $ec"
        exit $ec
    fi
done

flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter pub get
