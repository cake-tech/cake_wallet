#!/bin/sh

./install_ndk.sh
./build_monero_all.sh
./build_wownero.sh
./build_wownero_seed.sh
./git_versions.sh
./copy_monero_deps.sh
./copy_wownero_deps.sh

