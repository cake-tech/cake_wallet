#!/bin/bash
set -x -e

for cwcoin in cw_{core,evm,monero,bitcoin,nano,bitcoin_cash,solana,tron,wownero,zano,decred,dogecoin,zcash,starknet}
do
    if [[ "x$1" == "xasync" ]];
    then
        bash -c "cd $cwcoin; flutter pub get; dart run build_runner build --delete-conflicting-outputs; cd .." &
    else
        cd $cwcoin; flutter pub get; dart run build_runner build --delete-conflicting-outputs; cd ..
    fi
done
for cwcoin in cw_mweb;
do
    if [[ "x$1" == "xasync" ]];
    then
        bash -c "cd $cwcoin; flutter pub get; cd .." &
    else
        cd $cwcoin; flutter pub get; cd ..
    fi
done

if [[ "x$1" == "xasync" ]];
then
    wait
fi

flutter pub get
dart run build_runner build --delete-conflicting-outputs
