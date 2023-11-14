#!/bin/sh

cd cw_core; flutter pub get; dart run build_runner build --delete-conflicting-outputs; cd ..
cd cw_monero; flutter pub get; dart run build_runner build --delete-conflicting-outputs; cd ..
cd cw_bitcoin; flutter pub get; dart run build_runner build --delete-conflicting-outputs; cd ..
cd cw_haven; flutter pub get; dart run build_runner build --delete-conflicting-outputs; cd ..
cd cw_ethereum; flutter pub get; dart run build_runner build --delete-conflicting-outputs; cd ..
cd cw_nano; flutter pub get; dart run build_runner build --delete-conflicting-outputs; cd ..
cd cw_bitcoin_cash; flutter pub get; dart run build_runner build --delete-conflicting-outputs; cd ..
dart run build_runner build --delete-conflicting-outputs
