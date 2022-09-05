#!/bin/sh

./install_ndk.sh
./build_monero_all.sh
./build_wownero_all.sh
./copy_monero_deps.sh

