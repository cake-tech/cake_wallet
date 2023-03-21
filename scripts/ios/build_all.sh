#!/bin/sh

./build_shared.sh
./build_monero_all.sh
./build_wownero_all.sh
./create_git_versions_file.sh
./setup.sh

