#!/bin/bash

mkdir -p build
./build_shared.sh
./build_monero_all.sh
./build_wownero_all.sh
./create_git_versions_file.sh
./build_monerolib.sh
./build_wownerolib.sh
