#!/bin/sh

./install_ndk.sh
./build_shared.sh
./build_monero.sh
./build_wownero.sh
./build_wownero_seed.sh
./create_git_versions_file.sh
./copy_monero_deps.sh
./copy_wownero_deps.sh

