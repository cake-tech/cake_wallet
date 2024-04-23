#!/bin/bash
set -x -e

ls /opt/android

rm -rf monero haven

./build_monero.sh
./build_haven.sh
./copy_monero_deps.sh
./copy_haven_deps.sh
