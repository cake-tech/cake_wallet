#!/bin/bash
set -x -e

for cwcoin in cw_{arbitrum,core,evm,monero,monerolws,bitcoin,nano,bitcoin_cash,solana,tron,wownero,zano,decred,dogecoin,base}
do
    if [[ "x$1" == "xasync" ]];
    then
        bash -c "cd $cwcoin; flutter pub get; dart run build_runner build --delete-conflicting-outputs; cd .." &
    else
        cd $cwcoin; flutter pub get; dart run build_runner build --delete-conflicting-outputs; cd ..
    fi
done
for cwcoin in cw_{polygon,ethereum,mweb};
do
    if [[ "x$1" == "xasync" ]];
    then
        bash -c "cd $cwcoin; flutter pub get; cd .." &
    else
        cd $cwcoin; flutter pub get; cd ..
    fi
done

flutter pub get
dart run build_runner build --delete-conflicting-outputs
