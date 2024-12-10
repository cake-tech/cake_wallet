#!/bin/bash
set -x -e

ls /opt/android

rm -rf monero haven salvium

./build_monero.sh
./build_haven.sh
./build_salvium.sh
./copy_monero_deps.sh
./copy_haven_deps.sh
./copy_salvium_deps.sh
